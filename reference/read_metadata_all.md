# Read all GeoNetwork / Geoportal metadata in chunks

This function uses
[`read_metadata()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata.md)
repeatedly to fetch **all** available metadata records from a GeoNetwork
endpoint that supports `from` / `to` pagination (like the GDI Berlin
instance).

## Usage

``` r
read_metadata_all(
  base_url =
    "https://gdi.berlin.de/geonetwork/srv/ger/q?facet.q=type/service&resultType=details&sortBy=changeDate&fast=index",
  chunk_size = 100
)
```

## Arguments

- base_url:

  Base GeoNetwork query URL **without** `from` and `to` parameters. Must
  return an XML with a `<summary count="...">` node. Defaults to the GDI
  Berlin service search.

- chunk_size:

  Number of records per request. Default: 100.

## Value

A tibble with one row per metadata record, identical in structure to the
return value of
[`read_metadata()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata.md),
but for **all** pages.

## Details

It first downloads the initial XML, reads the `<summary count="...">`
attribute to know how many records exist, then iterates in chunks
(default: 100) until all records are read.

## See also

[`read_metadata()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata.md)

## Examples

``` r
if (FALSE) { # \dontrun{
all_md <- read_metadata_all()
nrow(all_md)
} # }
```
