test_that("wfs_base_url() composes the endpoint", {
  expect_equal(
    wfs_base_url("atkis"),
    "https://gdi.berlin.de/services/wfs/atkis"
  )
  expect_equal(
    wfs_base_url("wsg", host = "https://example.org/wfs/"),
    "https://example.org/wfs/wsg"
  )
  expect_error(wfs_base_url(c("a", "b")))
  expect_error(wfs_base_url(""))
})

test_that("wfs_base_url() rejects what cannot be a service name", {
  # xml2::read_xml() parses any string containing "<" or ">" as literal XML
  # instead of fetching it, so a placeholder that reaches read_xml() fails with
  # "Start tag expected" rather than with anything the caller can act on.
  expect_error(wfs_base_url("<gefundener dienst>"), "not a WFS service name")
  expect_error(list_wfs_layers("<gefundener dienst>"), "not a WFS service name")
  expect_error(wfs_base_url("atkis wsg"), "not a WFS service name")
  expect_error(wfs_base_url("services/wfs/atkis"), "not a WFS service name")

  # A full URL stays a valid way to name the endpoint.
  expect_equal(
    wfs_base_url("atkis"),
    "https://gdi.berlin.de/services/wfs/atkis"
  )
})

test_that("compose_ogc_url() reproduces the URLs that the Berlin services answer", {
  # Both strings are taken verbatim from data-raw/kwb25_dashboard_fetch_rivers.R
  # and data-raw/kwb25_dashboard_fetch_wsg.R of kwb.BerlinWaterModel, where they
  # are known to return data.
  expected_rivers <- paste0(
    "https://gdi.berlin.de/services/wfs/atkis",
    "?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature",
    "&TYPENAMES=atkis:b17_ax_gewaesserstationierungsachse_l",
    "&SRSNAME=EPSG:25833",
    "&OUTPUTFORMAT=application/json"
  )

  expect_equal(
    compose_ogc_url(
      wfs_base_url("atkis"),
      SERVICE = "WFS",
      VERSION = "2.0.0",
      REQUEST = "GetFeature",
      TYPENAMES = "atkis:b17_ax_gewaesserstationierungsachse_l",
      SRSNAME = "EPSG:25833",
      OUTPUTFORMAT = "application/json"
    ),
    expected_rivers
  )

  expected_wsg <- paste0(
    "https://gdi.berlin.de/services/wfs/wsg",
    "?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature",
    "&TYPENAMES=wsg:wsg",
    "&SRSNAME=EPSG:25833",
    "&OUTPUTFORMAT=application/json"
  )

  expect_equal(
    compose_ogc_url(
      wfs_base_url("wsg"),
      SERVICE = "WFS",
      VERSION = "2.0.0",
      REQUEST = "GetFeature",
      TYPENAMES = "wsg:wsg",
      SRSNAME = "EPSG:25833",
      OUTPUTFORMAT = "application/json"
    ),
    expected_wsg
  )
})

test_that("encode_query_value() escapes what must be escaped", {
  expect_equal(encode_query_value("wsg:wsg"), "wsg:wsg")
  expect_equal(encode_query_value("application/json"), "application/json")
  expect_equal(encode_query_value("a b"), "a%20b")
  expect_equal(encode_query_value("a&b=c"), "a%26b%3Dc")
  expect_equal(encode_query_value("100"), "100")
})

test_that("compose_ogc_url() drops NULL and encodes values", {
  url <- compose_ogc_url(
    "https://example.org/wfs/x",
    SERVICE = "WFS",
    VERSION = "2.0.0",
    TYPENAMES = "x:layer",
    COUNT = NULL,
    OUTPUTFORMAT = "application/json"
  )

  expect_false(grepl("COUNT", url))
  expect_true(grepl("TYPENAMES=x:layer", url, fixed = TRUE))
  expect_true(grepl("OUTPUTFORMAT=application/json", url, fixed = TRUE))
  expect_equal(lengths(regmatches(url, gregexpr("?", url, fixed = TRUE))), 1L)
})

test_that("wfs_service_name() takes the last path element", {
  expect_equal(
    wfs_service_name("https://gdi.berlin.de/services/wfs/atkis?SERVICE=WFS"),
    "atkis"
  )
  expect_equal(wfs_service_name("https://example.org/wfs/wsg/"), "wsg")
  expect_true(is.na(wfs_service_name(NA_character_)))
})

test_that("find_wfs() filters by protocol and pattern without network", {
  metadata <- tibble::tibble(
    geonet_uuid = c("uuid-1", "uuid-2"),
    title = c("Kanalisation 2012", "Gewaesserkarte"),
    abstract = c("Kanalnetz Berlin", "Fliessgewaesser"),
    links = list(
      purrr::map_dfr(
        c(
          "|Downloaddienst (WFS)|https://gdi.berlin.de/services/wfs/kanal|OGC:WFS|||",
          "|Darstellungsdienst (WMS)|https://gdi.berlin.de/services/wms/kanal|OGC:WMS|||"
        ),
        parse_gn_link
      ),
      parse_gn_link(
        "|Downloaddienst (WFS)|https://gdi.berlin.de/services/wfs/gewkarte|OGC:WFS|||"
      )
    )
  )

  all_wfs <- find_wfs(metadata = metadata)
  expect_equal(nrow(all_wfs), 2L)
  expect_setequal(all_wfs$service, c("kanal", "gewkarte"))

  hit <- find_wfs("kanalisation", metadata = metadata)
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$service, "kanal")

  wms <- find_wfs(metadata = metadata, protocol = "OGC:WMS")
  expect_equal(nrow(wms), 1L)

  expect_equal(nrow(find_wfs("gibtesnicht", metadata = metadata)), 0L)
  expect_named(
    find_wfs("gibtesnicht", metadata = metadata),
    c("title", "service", "link_url", "link_desc", "link_protocol", "geonet_uuid")
  )

  # A pattern that does not match is not a problem worth warning about.
  expect_silent(find_wfs("gibtesnicht", metadata = metadata))
})

test_that("find_wfs() distinguishes 'no links' from 'pattern did not match'", {
  # What the GDI Berlin service catalogue actually returns: records whose
  # <link> elements are absent, so every search comes back empty.
  linkless <- tibble::tibble(
    geonet_uuid = c("uuid-1", "uuid-2"),
    title = c("Kanalisation 2012", "ALKIS Flurstuecke"),
    abstract = c("Kanalnetz Berlin", "Liegenschaftskataster"),
    links = list(parse_gn_link(""), parse_gn_link(""))
  )

  expect_warning(
    result <- find_wfs("kanalisation", metadata = linkless),
    "carries a link"
  )
  expect_equal(nrow(result), 0L)
  expect_named(
    result,
    c("title", "service", "link_url", "link_desc", "link_protocol", "geonet_uuid")
  )

  # The warning does not depend on the pattern: there is nothing to search.
  expect_warning(find_wfs(metadata = linkless), "carries a link")
})

test_that("find_wfs() names the protocols on offer when none matches", {
  # Verbatim from the GDI Berlin catalogue: its INSPIRE download services are
  # published as "INSPIRE ATOM", so the "OGC:WFS" default matches nothing.
  metadata <- tibble::tibble(
    geonet_uuid = c("uuid-1", "uuid-2"),
    title = c("3D-Gebaeudemodelle", "Fahrradabstellanlagen"),
    abstract = c("LoD1", "Bestand und Planungen"),
    links = list(
      parse_gn_link(paste0(
        "|Downloaddienst - 3D-Gebaeudemodelle (ATOM)",
        "|https://gdi.berlin.de/data/a_lod1/atom/|INSPIRE ATOM|INSPIRE ATOM|1"
      )),
      parse_gn_link(
        "|Darstellungsdienst (WMS)|https://gdi.berlin.de/services/wms/rad|OGC:WMS|||"
      )
    )
  )

  expect_warning(
    result <- find_wfs("gebaeude", metadata = metadata),
    "No link uses the protocol 'OGC:WFS'"
  )
  expect_equal(nrow(result), 0L)

  # The message has to say what IS there, otherwise it is no better than the
  # empty tibble it replaces.
  expect_warning(find_wfs(metadata = metadata), "INSPIRE ATOM \\(1\\)")
  expect_warning(find_wfs(metadata = metadata), "OGC:WMS \\(1\\)")

  # Asking for a protocol that is there still works, and warns about nothing.
  expect_silent(atom <- find_wfs(metadata = metadata, protocol = "INSPIRE ATOM"))
  expect_equal(nrow(atom), 1L)
  expect_equal(atom$link_url, "https://gdi.berlin.de/data/a_lod1/atom/")

  # protocol = NULL keeps every link.
  expect_silent(all_links <- find_wfs(metadata = metadata, protocol = NULL))
  expect_equal(nrow(all_links), 2L)
})

test_that("describe_protocols() summarises counts, commonest first", {
  expect_equal(
    describe_protocols(c("OGC:WMS", "INSPIRE ATOM", "OGC:WMS")),
    "OGC:WMS (2), INSPIRE ATOM (1)"
  )
  expect_equal(describe_protocols(c(NA_character_, "")), "no protocol at all")
  expect_equal(
    describe_protocols(c("a", "b", "c"), max_shown = 2L),
    "a (1), b (1) and 1 more"
  )
})

# Verbatim from https://gdi.berlin.de/geonetwork/srv/ger/q?facet.q=type/service
# &resultType=details&sortBy=changeDate&fast=index&from=1&to=5 -- umlauts are
# written as \u escapes to keep this file ASCII.
GDI_LINKS <- c(
  atom = paste0(
    "|Downloaddienst - 3D-Geb\u00e4udemodelle im Level of Detail 1 (LoD 1) (ATOM)",
    "|https://gdi.berlin.de/data/a_lod1/atom/|INSPIRE ATOM|INSPIRE ATOM|1"
  ),
  wms = paste0(
    "|Darstellungsdienst - Fahrradabstellanlagen (seit 2021) (WMS)",
    "|https://gdi.berlin.de/services/wms/fahrradabstellanlagen",
    "?request=GetCapabilities&service=WMS",
    "|Darstellungsdienst - Fahrradabstellanlagen (seit 2021) (WMS)",
    "|Darstellungsdienst - Fahrradabstellanlagen (seit 2021) (WMS)|1"
  ),
  view = paste0(
    "|Darstellung der Karte im Geoportal Berlin",
    "|https://gdi.berlin.de/view/fahrradabstellanlagen||text/plain|2"
  ),
  wfs = paste0(
    "|Downloaddienst - Fahrradabstellanlagen (seit 2021) (WFS)",
    "|https://gdi.berlin.de/services/wfs/fahrradabstellanlagen",
    "?request=GetCapabilities&service=WFS",
    "|Downloaddienst - Fahrradabstellanlagen (seit 2021) (WFS)",
    "|Downloaddienst - Fahrradabstellanlagen (seit 2021) (WFS)|1"
  )
)

test_that("parse_gn_link() reads the real GDI Berlin records", {
  parsed <- purrr::map_dfr(GDI_LINKS, parse_gn_link)

  expect_equal(
    parsed$link_url,
    c(
      "https://gdi.berlin.de/data/a_lod1/atom/",
      paste0("https://gdi.berlin.de/services/wms/fahrradabstellanlagen",
             "?request=GetCapabilities&service=WMS"),
      "https://gdi.berlin.de/view/fahrradabstellanlagen",
      paste0("https://gdi.berlin.de/services/wfs/fahrradabstellanlagen",
             "?request=GetCapabilities&service=WFS")
    )
  )

  # The catalogue declares a protocol only for the ATOM link. The WMS and WFS
  # records repeat their description there, the viewer link leaves it empty.
  expect_equal(parsed$link_protocol[1], "INSPIRE ATOM")
  expect_match(parsed$link_protocol[2], "^Darstellungsdienst")
  expect_true(is.na(parsed$link_protocol[3]))
  expect_match(parsed$link_protocol[4], "^Downloaddienst")

  expect_equal(parsed$link_order, c("1", "1", "2", "1"))
})

test_that("gn_link_protocol() takes the protocol from the URL", {
  parsed <- purrr::map_dfr(GDI_LINKS, parse_gn_link)
  effective <- gn_link_protocol(parsed$link_url, parsed$link_protocol)

  expect_equal(effective[1], "INSPIRE ATOM")   # declared, and usable
  expect_equal(effective[2], "OGC:WMS")        # repaired from the URL
  expect_true(is.na(effective[3]))             # a viewer page, not a service
  expect_equal(effective[4], "OGC:WFS")        # repaired from the URL

  # A catalogue that fills the field in properly is left alone.
  expect_equal(
    gn_link_protocol("https://example.org/anything", "OGC:WFS"),
    "OGC:WFS"
  )
  # Either spelling is enough on its own.
  expect_equal(gn_link_protocol("https://x/services/wfs/y", NA), "OGC:WFS")
  expect_equal(gn_link_protocol("https://x/y?service=wfs", NA), "OGC:WFS")
  # WMTS must not be read as WMS.
  expect_equal(gn_link_protocol("https://x/y?service=WMTS", NA), "OGC:WMTS")
  expect_true(is.na(gn_link_protocol(NA_character_, NA_character_)))
})

test_that("find_wfs() finds the WFS the declared protocol hid", {
  metadata <- tibble::tibble(
    geonet_uuid = "uuid-1",
    title = "Fahrradabstellanlagen (seit 2021)",
    abstract = "Bestand und Planungen von Fahrradabstellanlagen",
    links = list(purrr::map_dfr(GDI_LINKS, parse_gn_link))
  )

  hit <- find_wfs("fahrradabstellanlagen", metadata = metadata)
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$service, "fahrradabstellanlagen")
  expect_equal(hit$link_protocol, "OGC:WFS")

  # read_wfs() takes that service name as its first argument.
  expect_equal(
    wfs_base_url(hit$service),
    "https://gdi.berlin.de/services/wfs/fahrradabstellanlagen"
  )

  wms <- find_wfs(metadata = metadata, protocol = "OGC:WMS")
  expect_equal(nrow(wms), 1L)
  expect_equal(wms$service, "fahrradabstellanlagen")
})

test_that("wfs_endpoint() drops the catalogue's own query string", {
  # This is exactly what find_wfs() reports in its link_url column.
  reported <- paste0(
    "https://gdi.berlin.de/services/wfs/ua_kanalisation_2012",
    "?request=GetCapabilities&service=WFS"
  )
  expect_equal(
    wfs_endpoint(reported),
    "https://gdi.berlin.de/services/wfs/ua_kanalisation_2012"
  )

  # A request built from it has one query string, not two, and the namespace
  # prefix comes from the path.
  url <- compose_ogc_url(
    wfs_endpoint(reported),
    SERVICE = "WFS", VERSION = "2.0.0", REQUEST = "GetFeature",
    TYPENAMES = "ua_kanalisation_2012:ua_kanalisation_2012"
  )
  expect_equal(lengths(regmatches(url, gregexpr("?", url, fixed = TRUE))), 1L)
  expect_equal(sub("^.*/", "", wfs_endpoint(reported)), "ua_kanalisation_2012")

  # A bare name and a clean URL still work, and a trailing slash is dropped.
  expect_equal(
    wfs_endpoint("ua_kanalisation_2012"),
    "https://gdi.berlin.de/services/wfs/ua_kanalisation_2012"
  )
  expect_equal(
    wfs_endpoint("https://example.org/wfs/x/"),
    "https://example.org/wfs/x"
  )
  expect_error(wfs_endpoint("<gefundener dienst>"), "not a WFS service name")
})
