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
#' GeoNetwork often encodes links as a single string separated by `|`, e.g.:
#' `|Darstellungsdienst (WMS)|https://...|OGC:WMS|||`.
#' This helper splits such a string into named columns and pads missing parts
#' up to 6 elements.
#'
#' The order used here is:
#' 1. link name
#' 2. link description
#' 3. link URL
#' 4. link protocol (e.g. `"OGC:WMS"`)
#' 5. MIME type
#' 6. order
#'
#' Note: In many Berlin GDI records the **first** field (link name) is empty,
#' and the actual meaningful text is in the **second** field (description).
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
  # pad / trim to 6 elements
  if (length(parts) < 6) {
    parts <- c(parts, rep(NA_character_, 6 - length(parts)))
  } else if (length(parts) > 6) {
    parts <- parts[1:6]
  }
  tibble::tibble(
    link_name     = parts[1],
    link_desc     = parts[2],
    link_url      = parts[3],
    link_protocol = parts[4],
    link_mime     = parts[5],
    link_order    = parts[6]
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
      list(tibble::tibble(
        link_name     = NA_character_,
        link_desc     = NA_character_,
        link_url      = NA_character_,
        link_protocol = NA_character_,
        link_mime     = NA_character_,
        link_order    = NA_character_
      ))
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
