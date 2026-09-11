# Summarise the link protocols present in a catalogue

Summarise the link protocols present in a catalogue

## Usage

``` r
describe_protocols(x, max_shown = 10L)
```

## Arguments

- x:

  character vector of `link_protocol` values, `NA`s allowed.

- max_shown:

  number of protocols to name before summarising the rest.

## Value

character of length one, e.g. `"INSPIRE ATOM (826), OGC:WMS (776)"`.
