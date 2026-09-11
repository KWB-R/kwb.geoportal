# Tutorial

``` r

library(kwb.geoportal)
#> 
#> Attaching package: 'kwb.geoportal'
#> The following object is masked from 'package:base':
#> 
#>     %||%

metadata <- kwb.geoportal::read_metadata_all()

DT::datatable(metadata)
#> Warning in instance$preRenderHook(instance): It seems your data is too big for
#> client-side DataTables. You may consider server-side processing:
#> https://rstudio.github.io/DT/server.html
```
