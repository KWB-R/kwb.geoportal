#' Read a WFS layer (auto-detect from URL)
#'
#' Simplified helper to read a single WFS layer into R using \pkg{sf}.
#' The function automatically extracts the layer ID from the WFS URL,
#' assuming the URL pattern `.../wfs/<layer>?REQUEST=GetCapabilities...`.
#'
#' @param url character(1). Full WFS URL (e.g. a GetCapabilities link).
#' @param crs_target integer(1) or `NULL`. EPSG code to reproject the result to.
#'   Defaults to `25833` (ETRS89 / UTM zone 33N). Use `NULL` to keep native CRS.
#' @param bbox numeric(4) or `NULL`. Optional bounding box
#'   (`c(xmin, ymin, xmax, ymax)`), passed to the GetFeature request.
#' @param quiet logical(1). Suppress download messages (default: `FALSE`).
#'
#' @return An `sf` object with the requested WFS layer.
#' @export
#'
#' @examples
#' \dontrun{
#' # Read Berlin ALKIS Bezirke directly from GetCapabilities URL
#' bezirke <- read_wfs_sf_auto(
#'   "https://gdi.berlin.de/services/wfs/alkis_bezirke?REQUEST=GetCapabilities&SERVICE=wfs"
#' )
#' plot(bezirke["bezirk"])
#' }
#'
#' @importFrom sf st_read st_transform
#' @importFrom stringr str_extract
read_wfs_sf_auto <- function(url,
                             crs_target = 25833,
                             bbox = NULL,
                             quiet = FALSE) {

  stopifnot(is.character(url), length(url) == 1)

  # 1) Layer-ID automatisch aus URL extrahieren
  layer_id <- stringr::str_extract(url, "(?<=/wfs/)[^/?]+")
  if (is.na(layer_id)) {
    stop("Could not extract layer ID from URL: ", url)
  }

  # 2) Basis-URL bis einschließlich /wfs/<id>
  base_url <- sub("\\?.*$", "", url)

  # 3) Explizite GetFeature-Anfrage zusammenbauen
  getfeature_url <- paste0(
    base_url,
    "?service=WFS&version=2.0.0&request=GetFeature&typeNames=",
    layer_id
  )

  if (!is.null(bbox)) {
    stopifnot(is.numeric(bbox), length(bbox) == 4)
    getfeature_url <- paste0(getfeature_url, "&bbox=", paste(bbox, collapse = ","))
  }

  # 4) Lesen
  message("Reading WFS layer: ", layer_id)
  obj <- try(sf::st_read(getfeature_url, quiet = quiet), silent = TRUE)
  if (inherits(obj, "try-error")) {
    stop("Failed to read WFS layer from: ", getfeature_url)
  }

  # 5) Optional reprojection
  if (!is.null(crs_target)) {
    obj <- sf::st_transform(obj, crs_target)
  }

  obj
}
