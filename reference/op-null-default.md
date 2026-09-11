# Null-coalescing helper

Small utility to replace `NULL` or zero-length objects by a default
value. This is handy when parsing GeoNetwork JSON/XML responses where
some elements are simply missing.

## Usage

``` r
x %||% y
```

## Arguments

- x:

  Any object that might be `NULL` or of length 0.

- y:

  Fallback value to be returned when `x` is `NULL` or length 0.

## Value

Either `x` (when present) or `y` (when `x` is missing).
