# Percent-encode a query parameter value

`utils::URLencode(reserved = TRUE)` also escapes colon and slash, which
RFC 3986 explicitly permits inside a query component. Some OGC servers
are literal about the feature type they are given, so those two
characters are left alone; everything outside the unreserved set is
escaped.

## Usage

``` r
encode_query_value(x)
```

## Arguments

- x:

  value to encode.

## Value

character of length one.
