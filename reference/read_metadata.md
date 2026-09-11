# Read GeoNetwork service metadata (one row per service)

This function reads a GeoNetwork XML search response (as delivered by
`https://gdi.berlin.de/geonetwork/srv/ger/q?...`) and converts it into a
tidy tibble with **one row per metadata record**. All `<link>` elements
of a record are kept together in a **list column** called `links`, where
each entry is itself a tibble created by
[`parse_gn_link()`](https://kwb-r.github.io/kwb.geoportal/reference/parse_gn_link.md).

## Usage

``` r
read_metadata(path_xml)
```

## Arguments

- path_xml:

  Path or URL to the GeoNetwork XML document. This can be a local file
  (e.g. `"geoportal_metadaten.xml"`) or a remote URL such as
  `"https://gdi.berlin.de/geonetwork/srv/ger/q?..."`.

## Value

A tibble with one row per metadata record and the columns:

- geonet_uuid:

  UUID from `<geonet:info><uuid>` (character).

- geonet_id:

  Internal GeoNetwork id from `<geonet:info><id>` (character).

- title:

  Dataset/service title.

- abstract:

  Dataset/service abstract/description.

- serviceType:

  Service type, if present (e.g. WMS).

- types:

  Semicolon-separated `<type>` elements.

- source_logo:

  Logo path, if present.

- links:

  List column; each element is a tibble with the parsed links.

## Details

This structure is convenient when you want to keep the dataset-level
information (title, abstract, uuid, ...) together, but still be able to
inspect or unnest all service/download/view links later on.

The function assumes a GeoNetwork-style XML with `<metadata>` elements
and the namespace `geonet:` available for the info block. It is tailored
to the GDI Berlin instance but should work for other similar GeoNetwork
responses that use the same link encoding (`|` separated).

If a record has **no** `<link>` elements, the `links` column will
contain a single-row tibble with all `NA` values. This preserves the 1:1
alignment between records and rows.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- read_geonetwork_services(
  "https://gdi.berlin.de/geonetwork/srv/ger/q?facet.q=type/service&resultType=details&sortBy=changeDate&from=1&to=100&fast=index"
)
dplyr::glimpse(df)
df$links[[1]]
} # }
```
