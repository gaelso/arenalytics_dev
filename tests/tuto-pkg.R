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
# # Checks
# Sys.setenv("_R_CHECK_SYSTEM_CLOCK_" = 0) ; devtools::check()
#
# ## Publish app:
# ## - shinyapps.io: open ~/app.R then run:
# rsconnect::deployApp()
#
# ## UPDATE 2024: To publish to connect cloud, create manifest
# rsconnect::writeManifest()
#
#
# ## Note on git configuration
# ## - main repo: https://github.com/openforis/arenalytics
# ## - On Github: fork then change name to 'arenalytics_dev': https://github.com/gaelso/arenalytics_dev
# ## - In Rstudio: Create Rstudio project with fork
# ## - In Rstudio: Git tab > New Branch, call it 'dev'
# ## - Setup upstream: git remote add upstream https://github.com/openforis/arenalytics
# ## - Before each session: git fetch upstream
# ## - If changes:
# ## git checkout master
# ## git pull upstream master
# ## git push                 # updates your fork's master
# ## git checkout dev
# ## git merge master         # brings changes into dev
# ## git push
# ## - Finally push changes from branch to origin
# ## git checkout master
# ## git merge dev
# ## git push                 # updates fork's master
# ## git push upstream master # pushes to org
# ## git checkout dev         # back to work
#
# ## As diagram:
# work + commit on   local dev
# │
# │  git checkout master
# │  git merge --no-ff dev
# ▼
# local master        ← the only branch that crosses to upstream
# │
# ├─ git push origin master     → your fork's master (clean mirror)
#         └─ git push upstream master   → openforis (the public repo)
#
#    git checkout dev     ← back to work
#
#
#
#
# ##
# ## Push the app to the main repo (openforis/arenalytics) ######
# ##
#
# ## + Before the pull request ======
# ## - Commit all changes on the working branch (e.g. 'branding'), then:
# ## devtools::document()                   # NAMESPACE + man/ up to date
# ## devtools::check()                      # what CI runs (expected NOTE: licence stub)
# ## pkgdown::build_site(preview = FALSE)    # optional: check the docs site locally (docs/ is gitignored)
# ## source("data-raw/write_manifest.R")     # deployment manifest, from committed files only; commit it
# ## - Merge into the fork's master (through dev if that is the flow) and push:
# ## git checkout dev && git merge branding
# ## git checkout master && git merge dev
# ## git push origin dev master
#
# ## + Pull request ======
# ## - GitHub: gaelso/arenalytics_dev > Contribute > Open pull request
# ##   base: openforis/arenalytics master  <-  head: gaelso/arenalytics_dev master
# ## - CI runs R-CMD-check on the pull request. Merge when green (maintainer of openforis/arenalytics).
#
# ## + After the merge ======
# ## - Docs site: the pkgdown workflow builds and deploys https://openforis.github.io/arenalytics/
# ##   automatically on each push to master (Actions > pkgdown; can be re-run with 'Run workflow').
# ##   The app links to its articles (offline-install, latest-developments): check they open.
# ## - shinyapps.io: from an up-to-date master, rsconnect::deployApp() (see app.R).
# ## - Posit Connect Cloud: republish from the Connect Cloud dashboard (it reads app.R and
# ##   manifest.json from the GitHub repo), unless automatic publishing on push is switched on.
# ## - Offline bundle: from master, source("data-raw/make_offline_bundle.R"), then upload the two
# ##   zips to the folder linked in vignettes/offline-install.Rmd (the bundle holds a copy of the
# ##   package, so it must be rebuilt for each release).
# ## - Sync the fork: git fetch upstream && git checkout master && git merge upstream/master && git push
#
#
#
# ##
# ## Move to un-fao after official approval ######
# ##
#
# ## + Accounts and services ======
# ## - GitHub: transfer the repository and set up the dev forks (next section).
# ## - shinyapps.io: deploy under the FAO account:
# ##   rsconnect::setAccountInfo(name = "<fao-account>", token = "...", secret = "...")
# ##   rsconnect::deployApp(appName = "arenalytics", account = "<fao-account>")
# ## - Posit Connect Cloud: publish from un-fao/arenalytics under the FAO account; record the new URL.
# ## - Simple Analytics (script in R/shiny_run_arenalytics.R): add the new app domains to the site settings.
# ## - Offline bundle: move the zips from Google Drive to an FAO location or to GitHub release assets.
#
# ## + Move the repository and set up the dev forks ======
# ## Target set-up, all in the same GitHub fork network (pull requests work between any of them):
# ##   un-fao/arenalytics           production: releases, docs site, deployments
# ##   openforis/arenalytics_dev    team dev fork: integration of changes before release
# ##   gaelso/arenalytics_dev       personal dev fork (the current one)
#
# ## 1. Prepare
# ## - Merge or close open pull requests on openforis/arenalytics; tell collaborators about the move.
# ## - Check with the un-fao org owners who can create or receive repositories there: the person
# ##   doing the transfer needs admin rights on openforis/arenalytics and repo creation rights in un-fao.
# ## - Check that no repository named 'arenalytics' already exists in un-fao.
#
# ## 2. Transfer openforis/arenalytics to un-fao
# ## - openforis/arenalytics > Settings > General > Danger Zone > Transfer ownership > un-fao.
# ## - The transfer keeps the history, issues, pull requests, stars and the fork network:
# ##   gaelso/arenalytics_dev becomes a fork of un-fao/arenalytics automatically.
# ## - github.com/openforis/arenalytics redirects to un-fao/arenalytics, as long as no new repository
# ##   named 'arenalytics' is created in openforis. Never re-create it, or the redirect stops.
# ## - The docs site (openforis.github.io/arenalytics) does NOT redirect.
#
# ## 3. Set up un-fao/arenalytics
# ## - Settings > Collaborators and teams: re-add people and teams with the right roles.
# ## - Settings > Actions: allow actions; Settings > Pages > Source: GitHub Actions.
# ## - Settings > Branches: protect master (pull requests and passing R-CMD-check required).
# ## - Update the URLs listed below in one pull request; after the merge, the pkgdown workflow
# ##   publishes https://un-fao.github.io/arenalytics/.
#
# ## 4. Create the team dev fork openforis/arenalytics_dev
# ## - un-fao/arenalytics > Fork > Owner: openforis, Repository name: arenalytics_dev,
# ##   untick 'Copy the master branch only' to also copy dev if it exists.
# ## - In the fork: Actions tab > enable workflows (they are off by default in forks).
# ## - Create the dev branch if missing and make it the default branch (Settings > General).
# ## - Optional: disable the pkgdown workflow there (Actions > pkgdown > Disable workflow) unless
# ##   GitHub Pages is set up for the fork, otherwise every push to master shows a failed run.
#
# ## 5. Keep the personal dev fork gaelso/arenalytics_dev
# ## - No change on GitHub: after step 2 its parent is un-fao/arenalytics. GitHub does not allow a
# ##   second fork of the same network in the same account, and the parent of a fork cannot be
# ##   changed, so keep this fork rather than re-forking from openforis/arenalytics_dev.
# ## - Update the local remotes:
# ## git remote set-url upstream https://github.com/un-fao/arenalytics
# ## git remote add team https://github.com/openforis/arenalytics_dev
# ## git fetch --all
# ## git remote -v   # origin = gaelso/arenalytics_dev, team = openforis/arenalytics_dev, upstream = un-fao/arenalytics
#
# ## 6. Day-to-day flow
# ## - Personal work: branch in gaelso/arenalytics_dev, push to origin.
# ## - Integration: pull request gaelso/arenalytics_dev (dev) -> openforis/arenalytics_dev (dev).
# ## - Release: pull request openforis/arenalytics_dev (master) -> un-fao/arenalytics (master),
# ##   then the 'After the merge' steps above (docs, deployments, offline bundle).
# ## - Keep forks in sync with production:
# ## git fetch upstream && git checkout master && git merge upstream/master && git push origin master
# ## (and the same for team: git push team master, for maintainers of openforis/arenalytics_dev)
#
# ## + URLs to update in this repo ======
# ## Find them all with:
# ##   grep -rn "openforis/arenalytics\|openforis.github.io/arenalytics\|openforis-shiny.shinyapps.io" --exclude-dir=docs .
#
# ## GitHub repo: https://github.com/openforis/arenalytics -> https://github.com/un-fao/arenalytics
# ## - DESCRIPTION: URL and BugReports
# ## - README.md: R-CMD-check badge (badge image and link) and install_github("openforis/arenalytics")
# ## - _pkgdown.yml: navbar GitHub link
# ## - R/mod_home_UI.R: GitHub link in the first feature card
# ## - R/mod_about_UI.R: Context card "Source code on GitHub", Package card source code link and its
# ##   text, install code (install_github)
# ## - vignettes/user-guide.Rmd: install_github
# ## - CLAUDE.md: production repo and docs site
# ## - tests/tuto-pkg.R: upstream remote set-up (this file)
#
# ## Docs site: https://openforis.github.io/arenalytics/ -> https://un-fao.github.io/arenalytics/
# ## - DESCRIPTION: URL
# ## - _pkgdown.yml: url
# ## - R/mod_about_UI.R: Documentation link and its text, offline installation bundle link
# ##   (articles/offline-install.html), Full changelog link (articles/latest-developments.html)
#
# ## Live app: https://openforis-shiny.shinyapps.io/arenalytics/ -> FAO shinyapps.io or Connect Cloud URL
# ## - README.md: "Run at"
# ## - _pkgdown.yml: home link "Live app"
# ## - R/mod_about_UI.R: "Open the online version"
# ## - R/mod_tool_server.R: report author line ("Prepared with ArenaLytics | <url> | <date>")
# ## - tests/check-toolserver.R: same report line (mirror of the tool server)
# ## - vignettes/user-guide.Rmd: online version link
#
# ## Outside this repo
# ## - Open Foris Arena user manual (Google Doc), ArenaLytics section: online version URL and install command
# ## - vignettes/offline-install.Rmd: Google Drive link to the offline bundles, if they move
# ## - openforis.org and other pages linking to the live app or the GitHub repo
#
# ## Unchanged: openforis.org and Open Foris Arena links, the Arena user manual link (unless it moves),
# ## and the dev fork links (gaelso/arenalytics_dev) in README.md.
