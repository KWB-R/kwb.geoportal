#' Base URL of a Berlin Geoportal WFS service
#'
#' The Berlin spatial data infrastructure publishes one WFS endpoint per
#' dataset under a common path, e.g. `https://gdi.berlin.de/services/wfs/atkis`
#' for the ATKIS layers. This helper only composes that URL; it does not
#' contact the server.
#'
#' @param service name of the service, i.e. the last path element of the WFS
#'   endpoint (e.g. `"atkis"`, `"wsg"`). This is also the namespace prefix of
#'   the feature types offered by that service.
#' @param host base path of the WFS endpoints (default:
#'   `"https://gdi.berlin.de/services/wfs"`).
#'
#' @return character of length one, the service URL without query string.
#'   Signals an error when `service` is not a single path element, because the
#'   resulting URL would otherwise be handed to `xml2::read_xml()`, which parses
#'   any string containing `<` or `>` as literal XML rather than fetching it.
#' @export
#' @examples
#' wfs_base_url("atkis")
wfs_base_url <- function(
    service,
    host = "https://gdi.berlin.de/services/wfs"
) {
  stopifnot(is.character(service), length(service) == 1L, nzchar(service))

  if (grepl("[[:space:]<>?#/]", service)) {
    stop(sprintf(
      paste0(
        "'%s' is not a WFS service name. Expected the last path element of an ",
        "endpoint URL, such as \"atkis\", or a full https:// URL. ",
        "Use find_wfs() to look one up."
      ),
      service
    ), call. = FALSE)
  }

  paste0(sub("/+$", "", host), "/", service)
}

#' Endpoint URL of a service given either way of naming it
#'
#' [read_wfs()] and [list_wfs_layers()] accept either a service name or a full
#' endpoint URL. The URL that [find_wfs()] reports carries the catalogue's own
#' query string -- `?request=GetCapabilities&service=WFS` -- which has to go
#' before a new query string is appended, or the request ends up with two `?`
#' and the namespace prefix is read from the query rather than from the path.
#'
#' @param service service name or endpoint URL.
#' @param host see [wfs_base_url()].
#'
#' @return character of length one, an endpoint URL without query string.
#' @keywords internal
wfs_endpoint <- function(service, host = "https://gdi.berlin.de/services/wfs") {
  if (grepl("^https?://", service)) {
    sub("/+$", "", sub("[?#].*$", "", service))
  } else {
    wfs_base_url(service, host = host)
  }
}

#' Percent-encode a query parameter value
#'
#' `utils::URLencode(reserved = TRUE)` also escapes colon and slash, which
#' RFC 3986 explicitly permits inside a query component. Some OGC servers are
#' literal about the feature type they are given, so those two characters are
#' left alone; everything outside the unreserved set is escaped.
#'
#' @param x value to encode.
#'
#' @return character of length one.
#' @keywords internal
encode_query_value <- function(x) {
  characters <- strsplit(as.character(x), "", fixed = TRUE)[[1L]]

  if (length(characters) == 0L) {
    return("")
  }

  keep <- grepl("^[A-Za-z0-9._~:/,-]$", characters)

  encoded <- vapply(characters, function(ch) {
    paste0("%", toupper(sprintf("%02x", as.integer(charToRaw(ch)))),
           collapse = "")
  }, character(1L), USE.NAMES = FALSE)

  paste0(ifelse(keep, characters, encoded), collapse = "")
}

#' Compose an OGC request URL
#'
#' @param base_url endpoint URL without query string.
#' @param ... named request parameters. `NULL` entries are dropped, values are
#'   percent-encoded by [encode_query_value()].
#'
#' @return character of length one.
#' @keywords internal
compose_ogc_url <- function(base_url, ...) {
  params <- list(...)
  params <- params[!vapply(params, is.null, logical(1L))]

  query <- paste0(
    names(params), "=", vapply(params, encode_query_value, character(1L)),
    collapse = "&"
  )

  paste0(base_url, "?", query)
}

#' List the feature types offered by a WFS service
#'
#' Reads the service's `GetCapabilities` document and returns one row per
#' feature type. Use this to find out which `layer` to pass to
#' [read_wfs()] -- it is the authoritative source, unlike the catalogue,
#' which describes datasets rather than layers.
#'
#' @param service service name, see [wfs_base_url()], or a full endpoint URL.
#' @param version WFS version, one of `"2.0.0"` (default), `"1.1.0"`, `"1.0.0"`.
#' @param host see [wfs_base_url()].
#'
#' @return tibble with columns `typename`, `title`, `abstract`, `crs`.
#' @export
#' @importFrom xml2 read_xml xml_ns_strip xml_find_all xml_find_first xml_text
#' @importFrom tibble tibble
#' @importFrom purrr map_dfr
#' @examples
#' \dontrun{
#' list_wfs_layers("wsg")
#' }
list_wfs_layers <- function(
    service,
    version = c("2.0.0", "1.1.0", "1.0.0"),
    host = "https://gdi.berlin.de/services/wfs"
) {
  version <- match.arg(version)

  base_url <- wfs_endpoint(service, host = host)

  url <- compose_ogc_url(
    base_url,
    SERVICE = "WFS",
    VERSION = version,
    REQUEST = "GetCapabilities"
  )

  doc <- xml2::read_xml(url)

  # Namespaces differ between WFS versions; stripping them lets one XPath
  # expression work for all of them.
  xml2::xml_ns_strip(doc)

  feature_types <- xml2::xml_find_all(doc, ".//FeatureTypeList/FeatureType")

  if (length(feature_types) == 0L) {
    stop(sprintf(
      "No feature types found in the GetCapabilities response of '%s'.",
      base_url
    ), call. = FALSE)
  }

  purrr::map_dfr(feature_types, function(ft) {
    text_of <- function(xpath) {
      value <- xml2::xml_text(xml2::xml_find_first(ft, xpath))
      if (length(value) == 0L || is.na(value) || !nzchar(value)) {
        NA_character_
      } else {
        value
      }
    }

    tibble::tibble(
      typename = text_of("./Name"),
      title    = text_of("./Title"),
      abstract = text_of("./Abstract"),
      crs      = text_of("./DefaultCRS | ./DefaultSRS | ./SRS")
    )
  })
}

#' Read a WFS layer from the Berlin Geoportal
#'
#' Downloads one feature type of a WFS service and reads it into an `sf`
#' object. This is the data counterpart to [read_metadata()], which only
#' describes where a dataset lives.
#'
#' The request is a plain `GetFeature` call against
#' `<host>/<service>?SERVICE=WFS&VERSION=...&REQUEST=GetFeature&TYPENAMES=...`,
#' which is the form the Berlin endpoints answer.
#'
#' @param service service name, see [wfs_base_url()], or a full endpoint URL.
#' @param layer feature type to request. Either the fully qualified name
#'   (e.g. `"wsg:wsg"`) or the bare layer name, in which case the service name
#'   is used as the namespace prefix. If `NULL` (default) the service is asked
#'   for its feature types via [list_wfs_layers()]; this only succeeds when the
#'   service offers exactly one.
#' @param srs coordinate reference system of the response (default:
#'   `"EPSG:25833"`, the ETRS89 / UTM 33N used by the Berlin services).
#' @param version WFS version, one of `"2.0.0"` (default), `"1.1.0"`, `"1.0.0"`.
#' @param output_format value of `OUTPUTFORMAT` (default:
#'   `"application/json"`, i.e. GeoJSON). Pass `NULL` to let the server choose,
#'   which usually yields GML.
#' @param count maximum number of features to return, or `NULL` (default) for
#'   all of them. Sent as `COUNT` for WFS 2.0.0 and as `MAXFEATURES` otherwise.
#' @param start_index index of the first feature to return, or `NULL`
#'   (default). Together with `count` this allows paging through layers that
#'   exceed the server's response limit. WFS 2.0.0 only.
#' @param host see [wfs_base_url()].
#' @param quiet suppress the progress messages of [sf::read_sf()] and of this
#'   function (default: `FALSE`).
#'
#' @return an `sf` data frame.
#' @export
#' @importFrom utils download.file
#' @examples
#' \dontrun{
#' # Water protection zones, the layer the model's dashboard uses
#' wsg <- read_wfs("wsg", "wsg")
#'
#' # ATKIS river centrelines
#' rivers <- read_wfs("atkis", "b17_ax_gewaesserstationierungsachse_l")
#' }
read_wfs <- function(
    service,
    layer = NULL,
    srs = "EPSG:25833",
    version = c("2.0.0", "1.1.0", "1.0.0"),
    output_format = "application/json",
    count = NULL,
    start_index = NULL,
    host = "https://gdi.berlin.de/services/wfs",
    quiet = FALSE
) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for read_wfs().", call. = FALSE)
  }

  version <- match.arg(version)

  base_url <- wfs_endpoint(service, host = host)

  # A bare service name is the namespace prefix of its own feature types.
  prefix <- sub("^.*/", "", base_url)

  if (is.null(layer)) {
    layers <- list_wfs_layers(base_url, version = version)

    if (nrow(layers) != 1L) {
      stop(sprintf(
        paste0(
          "Service '%s' offers %d feature types, so 'layer' cannot be guessed. ",
          "Available: %s"
        ),
        base_url,
        nrow(layers),
        paste0("'", layers$typename, "'", collapse = ", ")
      ), call. = FALSE)
    }

    layer <- layers$typename
  }

  typename <- if (grepl(":", layer, fixed = TRUE)) {
    layer
  } else {
    paste0(prefix, ":", layer)
  }

  is_wfs2 <- identical(version, "2.0.0")

  url <- compose_ogc_url(
    base_url,
    SERVICE = "WFS",
    VERSION = version,
    REQUEST = "GetFeature",
    TYPENAMES = if (is_wfs2) typename else NULL,
    TYPENAME = if (!is_wfs2) typename else NULL,
    SRSNAME = srs,
    OUTPUTFORMAT = output_format,
    COUNT = if (is_wfs2) count else NULL,
    MAXFEATURES = if (!is_wfs2) count else NULL,
    STARTINDEX = if (is_wfs2) start_index else NULL
  )

  extension <- if (is.null(output_format) ||
                   !grepl("json", output_format, ignore.case = TRUE)) {
    ".gml"
  } else {
    ".geojson"
  }

  destination <- tempfile(fileext = extension)
  on.exit(unlink(destination), add = TRUE)

  if (!quiet) {
    message(sprintf("Requesting '%s' from %s", typename, base_url))
  }

  utils::download.file(url, destfile = destination, quiet = TRUE, mode = "wb")

  size_mb <- file.info(destination)$size / 1024^2

  if (is.na(size_mb) || size_mb == 0) {
    stop(sprintf("Empty response for '%s' from %s", typename, base_url),
         call. = FALSE)
  }

  # A WFS reports errors with HTTP 200 and an ExceptionReport body, which
  # sf would only complain about with an unhelpful driver message.
  first_bytes <- readChar(destination, nchars = 2000L, useBytes = TRUE)

  if (grepl("ExceptionReport|ServiceException", first_bytes)) {
    stop(sprintf(
      "The service returned an exception for '%s':\n%s",
      typename,
      trimws(substr(first_bytes, 1L, 1000L))
    ), call. = FALSE)
  }

  if (!quiet) {
    message(sprintf("Response: %.1f MB", size_mb))
  }

  sf::read_sf(destination, quiet = quiet)
}
