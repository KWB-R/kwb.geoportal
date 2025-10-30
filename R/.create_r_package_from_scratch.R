
# Install some packages
install.packages('kwb.pkgbuild')


usethis::create_package(".")
fs::file_delete(path = "DESCRIPTION")


author <- list(name = "Michael Rustler",
               orcid = "0000-0003-0647-7726",
               url = "https://mrustl.de")


pkg <- list(name = "kwb.geoportal",
            title = "R Package for getting spatial data from Berlin Geoportal (https://gdi.berlin.de/geonetwork/srv/ger/catalog.search#/search)",
            desc  = "R Package for getting spatial data from Berlin Geoportal (https://gdi.berlin.de/geonetwork/srv/ger/catalog.search#/search)) .")

kwb.pkgbuild::use_pkg(author,
                      pkg,
                      version = "0.0.0.9000",
                      stage = "experimental")


usethis::use_vignette("tutorial")

kwb.pkgbuild::use_ghactions()

kwb.pkgbuild::create_empty_branch_ghpages(pkg$name)
