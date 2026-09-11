# Changelog

## kwb.geoportal 0.0.0.9000

- Added
  [`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md),
  which downloads one feature type of a Berlin Geoportal WFS service and
  returns it as an `sf` object. This complements the metadata functions:
  [`read_metadata()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata.md)
  says where a dataset lives,
  [`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
  fetches it. Adds `sf` to `Imports`.

- Added
  [`list_wfs_layers()`](https://kwb-r.github.io/kwb.geoportal/reference/list_wfs_layers.md),
  which reads a service’s `GetCapabilities` document and returns one row
  per feature type. This is the authoritative way to find out which
  `layer` to pass to
  [`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md).

- Added
  [`find_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/find_wfs.md),
  which searches the catalogue read by
  [`read_metadata_all()`](https://kwb-r.github.io/kwb.geoportal/reference/read_metadata_all.md)
  for records offering a download service and returns one row per
  matching WFS link, including the `service` name that
  [`read_wfs()`](https://kwb-r.github.io/kwb.geoportal/reference/read_wfs.md)
  expects.

- Added
  [`wfs_base_url()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_base_url.md)
  and
  [`wfs_service_name()`](https://kwb-r.github.io/kwb.geoportal/reference/wfs_service_name.md)
  as small helpers around the endpoint URLs.

- Added `NEWS.md` file to track changes to the package.

- see <https://style.tidyverse.org/news.html> for writing a good
  `NEWS.md`
