# Compose an OGC request URL

Compose an OGC request URL

## Usage

``` r
compose_ogc_url(base_url, ...)
```

## Arguments

- base_url:

  endpoint URL without query string.

- ...:

  named request parameters. `NULL` entries are dropped, values are
  percent-encoded by
  [`encode_query_value()`](https://kwb-r.github.io/kwb.geoportal/reference/encode_query_value.md).

## Value

character of length one.
