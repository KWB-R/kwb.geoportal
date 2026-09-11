# kwb.geoportal 0.0.0.9000

* Added `read_wfs()`, which downloads one feature type of a Berlin Geoportal
  WFS service and returns it as an `sf` object. This complements the metadata
  functions: `read_metadata()` says where a dataset lives, `read_wfs()` fetches
  it. Adds `sf` to `Imports`.

* Added `list_wfs_layers()`, which reads a service's `GetCapabilities` document
  and returns one row per feature type. This is the authoritative way to find
  out which `layer` to pass to `read_wfs()`.

* Added `find_wfs()`, which searches the catalogue read by `read_metadata_all()`
  for records offering a download service and returns one row per matching WFS
  link, including the `service` name that `read_wfs()` expects.

* Added `wfs_base_url()` and `wfs_service_name()` as small helpers around the
  endpoint URLs.

* Added `NEWS.md` file to track changes to the package.

* see https://style.tidyverse.org/news.html for writing a good `NEWS.md`


