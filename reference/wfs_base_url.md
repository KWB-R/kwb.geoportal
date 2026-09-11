# Base URL of a Berlin Geoportal WFS service

The Berlin spatial data infrastructure publishes one WFS endpoint per
dataset under a common path, e.g.
`https://gdi.berlin.de/services/wfs/atkis` for the ATKIS layers. This
helper only composes that URL; it does not contact the server.

## Usage

``` r
wfs_base_url(service, host = "https://gdi.berlin.de/services/wfs")
```

## Arguments

- service:

  name of the service, i.e. the last path element of the WFS endpoint
  (e.g. `"atkis"`, `"wsg"`). This is also the namespace prefix of the
  feature types offered by that service.

- host:

  base path of the WFS endpoints (default:
  `"https://gdi.berlin.de/services/wfs"`).

## Value

character of length one, the service URL without query string. Signals
an error when `service` is not a single path element, because the
resulting URL would otherwise be handed to
[`xml2::read_xml()`](http://xml2.r-lib.org/reference/read_xml.md), which
parses any string containing `<` or `>` as literal XML rather than
fetching it.

## Examples

``` r
wfs_base_url("atkis")
#> [1] "https://gdi.berlin.de/services/wfs/atkis"
```
