#' Service name of a WFS endpoint URL
#'
#' Extracts the last path element of an endpoint URL, i.e. the name that
#' [read_wfs()] and [list_wfs_layers()] expect.
#'
#' @param url endpoint URL, with or without query string.
#'
#' @return character vector of service names, `NA` where none could be found.
#' @export
#' @examples
#' wfs_service_name("https://gdi.berlin.de/services/wfs/atkis?SERVICE=WFS")
wfs_service_name <- function(url) {
  path <- sub("[?#].*$", "", url)
  path <- sub("/+$", "", path)
  name <- sub("^.*/", "", path)
  ifelse(is.na(url) | !nzchar(name), NA_character_, name)
}

#' Find WFS services in the Geoportal catalogue
#'
#' Searches the GeoNetwork catalogue read by [read_metadata_all()] for records
#' that offer a download service, and returns one row per matching WFS link.
#' The `service` column of the result is what [read_wfs()] takes as its first
#' argument.
#'
#' This answers "which endpoint belongs to dataset X". It is a convenience for
#' discovery: once the service name is known it should be written down in the
#' calling code, so that fetching the data no longer depends on the catalogue
#' being reachable.
#'
#' @param pattern regular expression matched, case-insensitively, against the
#'   record title, its abstract and the link URL. `NULL` (default) returns
#'   every WFS link.
#' @param metadata result of a previous [read_metadata_all()] call. Pass this
#'   to search repeatedly without downloading the catalogue again. If `NULL`
#'   (default) the catalogue is read.
#' @param protocol link protocol to keep (default: `"OGC:WFS"`). Pass
#'   `"OGC:WMS"` to find map services instead, or `NULL` for all of them.
#' @param ... further arguments passed to [read_metadata_all()], e.g.
#'   `base_url`.
#'
#' @return tibble with columns `title`, `service`, `link_url`, `link_desc`,
#'   `link_protocol`, `geonet_uuid`, sorted by title. Warns, and returns no
#'   rows, when `metadata` holds no links at all, which is a different thing
#'   from `pattern` not matching.
#' @export
#' @importFrom purrr map_dfr
#' @importFrom tibble tibble as_tibble
#' @examples
#' \dontrun{
#' catalogue <- read_metadata_all()
#' find_wfs("kanalisation", metadata = catalogue)
#' find_wfs("alkis", metadata = catalogue)
#' }
find_wfs <- function(
    pattern = NULL,
    metadata = NULL,
    protocol = "OGC:WFS",
    ...
) {
  if (is.null(metadata)) {
    metadata <- read_metadata_all(...)
  }

  if (!"links" %in% names(metadata)) {
    stop("'metadata' must be a tibble as returned by read_metadata_all().",
         call. = FALSE)
  }

  flat <- purrr::map_dfr(seq_len(nrow(metadata)), function(i) {
    links <- metadata$links[[i]]

    if (is.null(links) || nrow(links) == 0L) {
      return(NULL)
    }

    tibble::as_tibble(cbind(
      links,
      title       = metadata$title[i],
      abstract    = metadata$abstract[i],
      geonet_uuid = metadata$geonet_uuid[i],
      stringsAsFactors = FALSE
    ))
  })

  if (nrow(flat) == 0L) {
    return(empty_wfs_result())
  }

  # Without this, a catalogue whose records carry no online resources at all is
  # indistinguishable from a pattern that simply does not match: both come back
  # as a zero-row tibble.
  if (!any(!is.na(flat$link_url) & nzchar(flat$link_url))) {
    warning(sprintf(
      paste0(
        "None of the %d catalogue records carries a link, so there is nothing ",
        "to search. The response of the 'base_url' passed to ",
        "read_metadata_all() contains no <link> elements."
      ),
      nrow(metadata)
    ), call. = FALSE)
    return(empty_wfs_result())
  }

  if (!is.null(protocol)) {
    keep <- !is.na(flat$link_protocol) &
      grepl(protocol, flat$link_protocol, fixed = TRUE)
    flat <- flat[keep, , drop = FALSE]
  }

  flat <- flat[!is.na(flat$link_url) & nzchar(flat$link_url), , drop = FALSE]

  if (!is.null(pattern)) {
    haystack <- paste(
      ifelse(is.na(flat$title), "", flat$title),
      ifelse(is.na(flat$abstract), "", flat$abstract),
      ifelse(is.na(flat$link_desc), "", flat$link_desc),
      flat$link_url
    )
    flat <- flat[grepl(pattern, haystack, ignore.case = TRUE), , drop = FALSE]
  }

  if (nrow(flat) == 0L) {
    return(empty_wfs_result())
  }

  result <- tibble::tibble(
    title         = flat$title,
    service       = wfs_service_name(flat$link_url),
    link_url      = flat$link_url,
    link_desc     = flat$link_desc,
    link_protocol = flat$link_protocol,
    geonet_uuid   = flat$geonet_uuid
  )

  result[order(result$title, result$service), , drop = FALSE]
}

#' Empty result of find_wfs()
#'
#' @return zero-row tibble with the columns of [find_wfs()].
#' @keywords internal
#' @importFrom tibble tibble
empty_wfs_result <- function() {
  tibble::tibble(
    title         = character(0),
    service       = character(0),
    link_url      = character(0),
    link_desc     = character(0),
    link_protocol = character(0),
    geonet_uuid   = character(0)
  )
}
