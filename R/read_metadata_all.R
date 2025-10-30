#' Read all GeoNetwork / Geoportal metadata in chunks
#'
#' This function uses [read_metadata()] repeatedly to fetch **all** available
#' metadata records from a GeoNetwork endpoint that supports `from` / `to`
#' pagination (like the GDI Berlin instance).
#'
#' It first downloads the initial XML, reads the `<summary count="...">`
#' attribute to know how many records exist, then iterates in chunks
#' (default: 100) until all records are read.
#'
#' @param base_url Base GeoNetwork query URL **without** `from` and `to`
#'   parameters. Must return an XML with a `<summary count="...">` node.
#'   Defaults to the GDI Berlin service search.
#' @param chunk_size Number of records per request. Default: 100.
#'
#' @return A tibble with one row per metadata record, identical in structure
#'   to the return value of [read_metadata()], but for **all** pages.
#'
#' @examples
#' \dontrun{
#' all_md <- read_metadata_all()
#' nrow(all_md)
#' }
#'
#' @seealso [read_metadata()]
#' @importFrom xml2 read_xml xml_find_first xml_attr
#' @importFrom dplyr bind_rows
#' @export
read_metadata_all <- function(
    base_url = "https://gdi.berlin.de/geonetwork/srv/ger/q?facet.q=type/service&resultType=details&sortBy=changeDate&fast=index",
    chunk_size = 100
) {
  # 1) Erstes Dokument holen, nur um die summary zu lesen
  doc0 <- xml2::read_xml(base_url)
  summary_node <- xml2::xml_find_first(doc0, ".//summary")
  total_count  <- as.integer(xml2::xml_attr(summary_node, "count"))

  if (is.na(total_count)) {
    stop("Could not read <summary count=\"...\"> from GDI Berlin GeoNetwork response.")
  }

  # 2) Sequenzen bilden: 1..total_count in chunk_size-Schritten
  from_vals <- seq(1, total_count, by = chunk_size)
  to_vals   <- pmin(from_vals + chunk_size - 1, total_count)

  # 3) Alle Chunks abrufen und parsen
  res_list <- vector("list", length(from_vals))

  for (i in seq_along(from_vals)) {
    from_i <- from_vals[i]
    to_i   <- to_vals[i]

    url_i <- sprintf("%s&from=%d&to=%d", base_url, from_i, to_i)

    # vorhandene Parserfunktion wiederverwenden
    res_list[[i]] <- read_metadata(url_i)
  }

  # 4) alles zusammenführen
  dplyr::bind_rows(res_list)
}
