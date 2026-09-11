# Parse a single GeoNetwork link element

GeoNetwork encodes links as a single string separated by `|`, e.g.:
`|Darstellungsdienst (WMS)|https://...|OGC:WMS|||`. This helper splits
such a string into named columns.

## Usage

``` r
parse_gn_link(x)
```

## Arguments

- x:

  Character string as found inside a `<link>` XML node.

## Value

A one-row tibble with columns:

- `link_name`

- `link_desc`

- `link_url`

- `link_protocol`

- `link_mime`

- `link_order`

## Details

The fields are ordered name, description, URL, protocol, MIME type,
order. The URL is the one field that can be recognised on its own, so it
is located first and the remaining fields are read relative to it; that
keeps the columns aligned for a catalogue that pads the record
differently.

Note that a parsed `link_protocol` is only as good as the catalogue: the
GDI Berlin records repeat the description there instead of naming a
protocol, so filtering on it needs
[`gn_link_protocol()`](https://kwb-r.github.io/kwb.geoportal/reference/gn_link_protocol.md).

## Examples

``` r
parse_gn_link("|Darstellungsdienst (WMS)|https://example.org/wms?|OGC:WMS|||")
#> # A tibble: 1 × 6
#>   link_name link_desc                link_url link_protocol link_mime link_order
#>   <chr>     <chr>                    <chr>    <chr>         <chr>     <chr>     
#> 1 NA        Darstellungsdienst (WMS) https:/… OGC:WMS       NA        NA        
```
