# Service name of a WFS endpoint URL

Extracts the last path element of an endpoint URL, i.e. the name that
[`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
and
[`list_wfs_layers()`](https://kwb-r.github.io/kwb.geoportal/reference/list_wfs_layers.md)
expect.

## Usage

``` r
wfs_service_name(url)
```

## Arguments

- url:

  endpoint URL, with or without query string.

## Value

character vector of service names, `NA` where none could be found.

## Examples

``` r
wfs_service_name("https://gdi.berlin.de/services/wfs/atkis?SERVICE=WFS")
#> [1] "atkis"
```
