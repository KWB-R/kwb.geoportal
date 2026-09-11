#' Null-coalescing helper
#'
#' Small utility to replace `NULL` or zero-length objects by a default value.
#' This is handy when parsing GeoNetwork JSON/XML responses where some
#' elements are simply missing.
#'
#' @param x Any object that might be `NULL` or of length 0.
#' @param y Fallback value to be returned when `x` is `NULL` or length 0.
#'
#' @return Either `x` (when present) or `y` (when `x` is missing).
#'
#' @name op-null-default
#' @keywords internal
#' @export
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


#' Parse a single GeoNetwork link element
#'
#' GeoNetwork encodes links as a single string separated by `|`, e.g.:
#' `|Darstellungsdienst (WMS)|https://...|OGC:WMS|||`.
#' This helper splits such a string into named columns.
#'
#' The fields are ordered name, description, URL, protocol, MIME type, order.
#' The URL is the one field that can be recognised on its own, so it is located
#' first and the remaining fields are read relative to it; that keeps the
#' columns aligned for a catalogue that pads the record differently.
#'
#' Note that a parsed `link_protocol` is only as good as the catalogue: the GDI
#' Berlin records repeat the description there instead of naming a protocol,
#' so filtering on it needs [gn_link_protocol()].
#'
#' @param x Character string as found inside a `<link>` XML node.
#'
#' @return A one-row tibble with columns:
#'   \itemize{
#'     \item `link_name`
#'     \item `link_desc`
#'     \item `link_url`
#'     \item `link_protocol`
#'     \item `link_mime`
#'     \item `link_order`
#'   }
#'
#' @examples
#' parse_gn_link("|Darstellungsdienst (WMS)|https://example.org/wms?|OGC:WMS|||")
#'
#' @importFrom tibble tibble
#' @export
parse_gn_link <- function(x) {
  if (is.null(x) || length(x) == 0) {
    x <- ""
  }

  parts <- strsplit(x, "\\|")[[1]]

  # Only fields that exist and carry something are worth reporting; everything
  # else is missing rather than empty.
  field <- function(i) {
    if (i >= 1L && i <= length(parts) && nzchar(parts[i])) {
      parts[i]
    } else {
      NA_character_
    }
  }

  at <- which(grepl("^[A-Za-z][A-Za-z0-9+.-]*://", parts))

  if (length(at) == 0L) {
    return(empty_gn_link())
  }

  at <- at[1L]

  tibble::tibble(
    link_name     = field(at - 2L),
    link_desc     = field(at - 1L),
    link_url      = parts[at],
    link_protocol = field(at + 1L),
    link_mime     = field(at + 2L),
    link_order    = field(at + 3L)
  )
}

#' One all-missing link row
#'
#' @return one-row tibble with the columns of [parse_gn_link()], all `NA`.
#' @keywords internal
#' @importFrom tibble tibble
empty_gn_link <- function() {
  tibble::tibble(
    link_name     = NA_character_,
    link_desc     = NA_character_,
    link_url      = NA_character_,
    link_protocol = NA_character_,
    link_mime     = NA_character_,
    link_order    = NA_character_
  )
}


#' Read GeoNetwork service metadata (one row per service)
#'
#' This function reads a GeoNetwork XML search response (as delivered by
#' `https://gdi.berlin.de/geonetwork/srv/ger/q?...`) and converts it into a
#' tidy tibble with **one row per metadata record**.
#' All `<link>` elements of a record are kept together in a **list column**
#' called `links`, where each entry is itself a tibble created by
#' [parse_gn_link()].
#'
#' This structure is convenient when you want to keep the dataset-level
#' information (title, abstract, uuid, ...) together, but still be able to
#' inspect or unnest all service/download/view links later on.
#'
#' @param path_xml Path or URL to the GeoNetwork XML document. This can be a
#'   local file (e.g. `"geoportal_metadaten.xml"`) or a remote URL such as
#'   `"https://gdi.berlin.de/geonetwork/srv/ger/q?..."`.
#'
#' @return A tibble with one row per metadata record and the columns:
#'   \describe{
#'     \item{geonet_uuid}{UUID from `<geonet:info><uuid>` (character).}
#'     \item{geonet_id}{Internal GeoNetwork id from `<geonet:info><id>` (character).}
#'     \item{title}{Dataset/service title.}
#'     \item{abstract}{Dataset/service abstract/description.}
#'     \item{serviceType}{Service type, if present (e.g. WMS).}
#'     \item{types}{Semicolon-separated `<type>` elements.}
#'     \item{source_logo}{Logo path, if present.}
#'     \item{links}{List column; each element is a tibble with the parsed links.}
#'   }
#'
#' @details
#' The function assumes a GeoNetwork-style XML with `<metadata>` elements and
#' the namespace `geonet:` available for the info block.
#' It is tailored to the GDI Berlin instance but should work for other similar
#' GeoNetwork responses that use the same link encoding (`|` separated).
#'
#' If a record has **no** `<link>` elements, the `links` column will contain
#' a single-row tibble with all `NA` values. This preserves the 1:1 alignment
#' between records and rows.
#'
#' @examples
#' \dontrun{
#' df <- read_geonetwork_services(
#'   "https://gdi.berlin.de/geonetwork/srv/ger/q?facet.q=type/service&resultType=details&sortBy=changeDate&from=1&to=100&fast=index"
#' )
#' dplyr::glimpse(df)
#' df$links[[1]]
#' }
#'
#' @importFrom xml2 read_xml xml_find_all xml_find_first xml_text
#' @importFrom purrr map_dfr
#' @importFrom tibble tibble
#' @importFrom stats setNames
#' @export
read_metadata <- function(path_xml) {
  doc <- xml2::read_xml(path_xml)
  mds <- xml2::xml_find_all(doc, ".//metadata")

  purrr::map_dfr(mds, function(md) {
    uuid  <- xml2::xml_text(xml2::xml_find_first(md, ".//geonet:info/uuid"))
    id    <- xml2::xml_text(xml2::xml_find_first(md, ".//geonet:info/id"))
    title <- xml2::xml_text(xml2::xml_find_first(md, ".//title"))
    abst  <- xml2::xml_text(xml2::xml_find_first(md, ".//abstract"))
    logo  <- xml2::xml_text(xml2::xml_find_first(md, ".//logo"))
    service_type <- xml2::xml_text(xml2::xml_find_first(md, ".//serviceType"))
    type_nodes   <- xml2::xml_find_all(md, ".//type")
    types        <- paste(xml2::xml_text(type_nodes), collapse = ";")

    link_nodes <- xml2::xml_find_all(md, ".//link")

    links_tbl <- if (length(link_nodes) == 0) {
      list(empty_gn_link())
    } else {
      list(purrr::map_dfr(link_nodes, ~parse_gn_link(xml2::xml_text(.x))))
    }

    tibble::tibble(
      geonet_uuid  = ifelse(uuid == "", NA_character_, uuid),
      geonet_id    = ifelse(id == "", NA_character_, id),
      title        = ifelse(title == "", NA_character_, title),
      abstract     = ifelse(abst == "", NA_character_, abst),
      serviceType  = ifelse(service_type == "", NA_character_, service_type),
      types        = ifelse(types == "", NA_character_, types),
      source_logo  = ifelse(logo == "", NA_character_, logo),
      links        = links_tbl
    )
  })
}
