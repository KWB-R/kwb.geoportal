# Read a WFS layer from the Berlin Geoportal

Downloads one feature type of a WFS service and reads it into an `sf`
object. This is the data counterpart to
[`read_metadata()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata.md),
which only describes where a dataset lives.

## Usage

``` r
read_wfs(
  service,
  layer = NULL,
  srs = "EPSG:25833",
  version = c("2.0.0", "1.1.0", "1.0.0"),
  output_format = "application/json",
  count = NULL,
  start_index = NULL,
  host = "https://gdi.berlin.de/services/wfs",
  quiet = FALSE
)
```

## Arguments

- service:

  service name, see
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md),
  or a full endpoint URL.

- layer:

  feature type to request. Either the fully qualified name (e.g.
  `"wsg:wsg"`) or the bare layer name, in which case the service name is
  used as the namespace prefix. If `NULL` (default) the service is asked
  for its feature types via
  [`list_wfs_layers()`](https://kwb-r.github.io/kwb.geoportal/reference/list_wfs_layers.md);
  this only succeeds when the service offers exactly one.

- srs:

  coordinate reference system of the response (default: `"EPSG:25833"`,
  the ETRS89 / UTM 33N used by the Berlin services).

- version:

  WFS version, one of `"2.0.0"` (default), `"1.1.0"`, `"1.0.0"`.

- output_format:

  value of `OUTPUTFORMAT` (default: `"application/json"`, i.e. GeoJSON).
  Pass `NULL` to let the server choose, which usually yields GML.

- count:

  maximum number of features to return, or `NULL` (default) for all of
  them. Sent as `COUNT` for WFS 2.0.0 and as `MAXFEATURES` otherwise.

- start_index:

  index of the first feature to return, or `NULL` (default). Together
  with `count` this allows paging through layers that exceed the
  server's response limit. WFS 2.0.0 only.

- host:

  see
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md).

- quiet:

  suppress the progress messages of
  [`sf::read_sf()`](https://r-spatial.github.io/sf/reference/st_read.html)
  and of this function (default: `FALSE`).

## Value

an `sf` data frame.

## Details

The request is a plain `GetFeature` call against
`<host>/<service>?SERVICE=WFS&VERSION=...&REQUEST=GetFeature&TYPENAMES=...`,
which is the form the Berlin endpoints answer.

## Examples

``` r
if (FALSE) { # \dontrun{
# Water protection zones, the layer the model's dashboard uses
wsg <- read_wfs("wsg", "wsg")

# ATKIS river centrelines
rivers <- read_wfs("atkis", "b17_ax_gewaesserstationierungsachse_l")
} # }
```
