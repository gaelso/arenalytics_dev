## ============================================================================
## write_manifest.R
##
## Regenerate manifest.json for shinyapps.io / Posit Connect Cloud, from the
## files the deployed app needs only: app.R, package metadata, R/ and inst/.
## Development scripts (tests/, data-raw/, vignettes/) are left out, so their
## packages (devtools, testthat, pkgdown...) do not end up in the deployment.
##
## Only files tracked by git are deployed: commit new files first.
## Packages and versions come from the local library: update them first.
##
## Run from the arenalytics project root after a dependency or asset change:
##   source("data-raw/write_manifest.R")
## ============================================================================

app_files <- system2(
  "git", c("ls-files", "--", "app.R", "DESCRIPTION", "NAMESPACE", "LICENSE", "R", "inst"),
  stdout = TRUE
)

rsconnect::writeManifest(appDir = ".", appFiles = app_files, appPrimaryDoc = "app.R")

## Check: packages in the manifest
manifest <- jsonlite::read_json("manifest.json")
message(sprintf(
  "[%s] manifest.json written: %s files, %s packages.",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"), length(manifest$files), length(manifest$packages)
))
