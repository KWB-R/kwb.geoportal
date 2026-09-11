# Find WFS services in the Geoportal catalogue

Searches the GeoNetwork catalogue read by
[`read_metadata_all()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata_all.md)
for records that offer a download service, and returns one row per
matching WFS link. The `service` column of the result is what
[`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
takes as its first argument.

## Usage

``` r
find_wfs(pattern = NULL, metadata = NULL, protocol = "OGC:WFS", ...)
```

## Arguments

- pattern:

  regular expression matched, case-insensitively, against the record
  title, its abstract and the link URL. `NULL` (default) returns every
  WFS link.

- metadata:

  result of a previous
  [`read_metadata_all()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata_all.md)
  call. Pass this to search repeatedly without downloading the catalogue
  again. If `NULL` (default) the catalogue is read.

- protocol:

  link protocol to keep (default: `"OGC:WFS"`). Pass `"OGC:WMS"` to find
  map services instead, or `NULL` for all of them.

- ...:

  further arguments passed to
  [`read_metadata_all()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata_all.md),
  e.g. `base_url`.

## Value

tibble with columns `title`, `service`, `link_url`, `link_desc`,
`link_protocol`, `geonet_uuid`, sorted by title. Warns, and returns no
rows, when `metadata` holds no links at all or none of them uses
`protocol` – both of which are a different thing from `pattern` not
matching. The second warning names the protocols that are on offer.

## Details

This answers "which endpoint belongs to dataset X". It is a convenience
for discovery: once the service name is known it should be written down
in the calling code, so that fetching the data no longer depends on the
catalogue being reachable.

## Examples

``` r
if (FALSE) { # \dontrun{
catalogue <- read_metadata_all()
find_wfs("kanalisation", metadata = catalogue)
find_wfs("alkis", metadata = catalogue)
} # }
```
