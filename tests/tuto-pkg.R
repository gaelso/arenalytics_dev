# ## Load install libraries (install first if needed)
# library(devtools)
# library(usethis)
# library(roxygen2)
#
# ## Create package in a version controled Rproject
# ## Requires overriding the .Rproj file
# usethis::create_package(".", open = FALSE)
#
# ## Add dependencies, i.e. all the packages that are needed to run the
# ## package's functions. Here is a non exhaustive list needed for the
# ## barebone app.
# ## + Shiny
# usethis::use_package("bsicons")
# usethis::use_package("bslib")
# usethis::use_package("htmltools")
# usethis::use_package("shiny")
# usethis::use_package("shiny.i18n")
# usethis::use_package("shinyjs")
# usethis::use_package("shinyWidgets")
# usethis::use_package("shinyFiles")
#
# ## + Tidyverse (Better to call packages individually)
# usethis::use_package("dplyr")
# usethis::use_package("rlang")
#
# ## + misc
# usethis::use_package("datasets")
# usethis::use_package("crosstalk")
# usethis::use_dev_package("d3scatter", remote = "jcheng5/d3scatter")
#
# ## Add license
# usethis::use_mit_license()
#
# ## Add github actions
# ## + package checks
# # usethis::use_github_action_check_standard()
# usethis::use_github_action("check-standard")
#
# ## + turn package doc into GH pages
# # usethis::use_pkgdown() ## NOT USE
# # usethis::use_github_action("pkgdown")
#
#
# ## Import R scripts
# dl_dir <- "R"
# gh_paths <- gh::gh(
#   "/repos/{owner}/{repo}/contents/{path}",
#   owner = "openforis", repo = "shinypkg-template", path = dl_dir
# )
#
# if (length(list.files(dl_dir)) == 0) {
#   dir.create(dl_dir)
#   purrr::walk(seq_along(gh_paths), function(x){
#     download.file(
#       url = gh_paths[[x]]$download_url,
#       destfile = gh_paths[[x]]$path
#     )
#   })
# }
#
# ## Import assets
# dl_dir <- "inst/assets"
# gh_paths <- gh::gh(
#   "/repos/{owner}/{repo}/contents/{path}",
#   owner = "openforis", repo = "shinypkg-template", path = dl_dir
# )
#
# if (length(list.files(dl_dir)) == 0) {
#   dir.create("inst")
#   dir.create(dl_dir)
#   purrr::walk(seq_along(gh_paths), function(x){
#     download.file(
#       url = gh_paths[[x]]$download_url,
#       destfile = gh_paths[[x]]$path
#     )
#   })
# }
#
# ## Run often
# devtools::document()
# devtools::install()
# devtools::load_all() ; shiny_run_arenalytics()
## Checks
# Sys.setenv("_R_CHECK_SYSTEM_CLOCK_" = 0) ; devtools::check()
#
#
# ## Moving from  arenalytics.dev to arenalytic main package
# ## 1. copy: R/, inst/, and DESCRIPTION only package if needed.
#
# root    <- "/Users/gaelsola/Github-collabs/arenalytics"
# patterns <- c("arenalytics\\.dev", "shiny_run_arenalytics_dev")
#
# file_paths <- list.files(root, recursive = TRUE, full.names = TRUE) |>
#   stringr::str_subset(pattern = "/man|/inst|NAMESPACE", negate = TRUE)
#
# purrr::map(file_paths, \(f) {
#   tryCatch({
#     lines   <- readLines(f, warn = FALSE)
#     matches <- grep(paste(patterns, collapse = "|"), lines)
#     if (length(matches) > 0) {
#       tibble::tibble(
#         file    = stringr::str_remove(f, stringr::fixed(root)),
#         line_no = matches,
#         content = stringr::str_trim(lines[matches])
#       )
#     }
#   }, error = \(e) NULL)
# }) |>
#   purrr::list_rbind()

## Note on git configuration
## - main repo: https://github.com/openforis/arenalytics
## - On Github: fork then change name to 'arenalytics_dev': https://github.com/gaelso/arenalytics.dev
## - In Rstudio: Create Rstudio project with fork
## - In Rstudio: Git tab > New Branch, call it 'dev'
## - Setup upstream: git remote add upstream https://github.com/openforis/arenalytics
## - Before each session: git fetch upstream
## - If changes:
## git checkout master
## git pull upstream master
## git push                 # updates your fork's master
## git checkout dev
## git merge master         # brings changes into dev
## git push
## - Finally push changes from branch to origin
## git checkout master
## git merge dev
## git push                 # updates fork's master
## git push upstream master # pushes to org
## git checkout dev         # back to work
