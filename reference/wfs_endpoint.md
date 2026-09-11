# Endpoint URL of a service given either way of naming it

[`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
and
[`list_wfs_layers()`](https://kwb-r.github.io/kwb.geoportal/reference/list_wfs_layers.md)
accept either a service name or a full endpoint URL. The URL that
[`find_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/find_wfs.md)
reports carries the catalogue's own query string –
`?request=GetCapabilities&service=WFS` – which has to go before a new
query string is appended, or the request ends up with two `?` and the
namespace prefix is read from the query rather than from the path.

## Usage

``` r
wfs_endpoint(service, host = "https://gdi.berlin.de/services/wfs")
```

## Arguments

- service:

  service name or endpoint URL.

- host:

  see
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md).

## Value

character of length one, an endpoint URL without query string.
