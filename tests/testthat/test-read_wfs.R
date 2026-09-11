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
})
