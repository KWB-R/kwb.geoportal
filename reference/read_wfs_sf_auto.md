# Read a WFS layer (auto-detect from URL)

Simplified helper to read a single WFS layer into R using sf. The
function automatically extracts the layer ID from the WFS URL, assuming
the URL pattern `.../wfs/<layer>?REQUEST=GetCapabilities...`.

## Usage

``` r
read_wfs_sf_auto(url, crs_target = 25833, bbox = NULL, quiet = FALSE)
```

## Arguments

- url:

  character(1). Full WFS URL (e.g. a GetCapabilities link).

- crs_target:

  integer(1) or `NULL`. EPSG code to reproject the result to. Defaults
  to `25833` (ETRS89 / UTM zone 33N). Use `NULL` to keep native CRS.

- bbox:

  numeric(4) or `NULL`. Optional bounding box
  (`c(xmin, ymin, xmax, ymax)`), passed to the GetFeature request.

- quiet:

  logical(1). Suppress download messages (default: `FALSE`).

## Value

An `sf` object with the requested WFS layer.

## Examples

``` r
if (FALSE) { # \dontrun{
# Read Berlin ALKIS Bezirke directly from GetCapabilities URL
bezirke <- read_wfs_sf_auto(
  "https://gdi.berlin.de/services/wfs/alkis_bezirke?REQUEST=GetCapabilities&SERVICE=wfs"
)
plot(bezirke["bezirk"])
} # }
```
