# List the feature types offered by a WFS service

Reads the service's `GetCapabilities` document and returns one row per
feature type. Use this to find out which `layer` to pass to
[`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
– it is the authoritative source, unlike the catalogue, which describes
datasets rather than layers.

## Usage

``` r
list_wfs_layers(
  service,
  version = c("2.0.0", "1.1.0", "1.0.0"),
  host = "https://gdi.berlin.de/services/wfs"
)
```

## Arguments

- service:

  service name, see
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md),
  or a full endpoint URL.

- version:

  WFS version, one of `"2.0.0"` (default), `"1.1.0"`, `"1.0.0"`.

- host:

  see
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md).

## Value

tibble with columns `typename`, `title`, `abstract`, `crs`.

## Examples

``` r
if (FALSE) { # \dontrun{
list_wfs_layers("wsg")
} # }
```
