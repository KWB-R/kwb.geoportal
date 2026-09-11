# Parse a single GeoNetwork link element

GeoNetwork often encodes links as a single string separated by `|`,
e.g.: `|Darstellungsdienst (WMS)|https://...|OGC:WMS|||`. This helper
splits such a string into named columns and pads missing parts up to 6
elements.

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

The order used here is:

1.  link name

2.  link description

3.  link URL

4.  link protocol (e.g. `"OGC:WMS"`)

5.  MIME type

6.  order

Note: In many Berlin GDI records the **first** field (link name) is
empty, and the actual meaningful text is in the **second** field
(description).

## Examples

``` r
parse_gn_link("|Darstellungsdienst (WMS)|https://example.org/wms?|OGC:WMS|||")
#> # A tibble: 1 × 6
#>   link_name link_desc                link_url link_protocol link_mime link_order
#>   <chr>     <chr>                    <chr>    <chr>         <chr>     <chr>     
#> 1 ""        Darstellungsdienst (WMS) https:/… OGC:WMS       ""        ""        
```
