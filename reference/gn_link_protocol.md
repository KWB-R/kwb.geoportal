# Protocol of a link, taken from its URL where the catalogue is unusable

A GeoNetwork link declares its protocol in its own field, but the GDI
Berlin records do not fill it in: their WMS and WFS links repeat the
description there, so `link_protocol` reads
`"Darstellungsdienst - ALKIS Berlin (WMS)"` where `"OGC:WMS"` is meant,
and their viewer links leave it empty. Filtering on the declared value
therefore drops every OGC service in the catalogue.

## Usage

``` r
gn_link_protocol(url, protocol = NA_character_)
```

## Arguments

- url:

  link URL, `NA` allowed.

- protocol:

  declared protocol, used where the URL says nothing.

## Value

character vector, as long as `url`.

## Details

The endpoint URL carries the same information and is machine-readable:
the Berlin services answer under `/services/<type>/<name>` and name the
type again in a `service=` query parameter. Where the URL says what the
service is, it wins; otherwise the declared protocol is kept as it is,
so a catalogue that fills the field in properly is unaffected.

## Examples

``` r
kwb.geoportal:::gn_link_protocol(
  "https://gdi.berlin.de/services/wfs/kanal?service=WFS",
  "Downloaddienst - Kanalisation (WFS)"
)
#> [1] "OGC:WFS"
```
