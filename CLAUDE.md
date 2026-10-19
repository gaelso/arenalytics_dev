# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

`arenalytics` is an R package that ships a Shiny dashboard ("Analytical Dashboard for Open Foris Arena"). Users upload a ZIP file produced by an Open Foris Arena processing chain; the app checks and reads it, shows survey insights, runs design-based survey estimation (means and totals per reporting dimension, via `srvyr`/`survey`), plots results and exports a Quarto report.

- This repo (`gaelso/arenalytics_dev`) is the development version. Production lives at `openforis/arenalytics`.
- Work happens on `dev`; `master` is the main branch (CI runs R-CMD-check on push/PR to `master`).
- Deployed on shinyapps.io / Posit Connect Cloud via `app.R` + `manifest.json` (regenerate the manifest with `rsconnect::writeManifest()` when dependencies change).

## Common commands

```r
devtools::load_all()                 # load package for interactive dev
arenalytics::shiny_run_arenalytics() # run the app
devtools::document()                 # regenerate NAMESPACE + man/ from roxygen
devtools::check()                    # R CMD check (what CI runs)
pkgdown::build_site()                # docs site (config in _pkgdown.yml)
```

There is **no testthat suite**. Files in `tests/` are manual check scripts run line by line after `devtools::load_all()`:
- `tests/check-toolserver.R` — rebuilds `rv` / `input` as plain lists and replays the tool module server logic outside Shiny.
- `tests/check-arenalyse.R`, `tests/check-data.R` — ad-hoc checks of core functions.
- `tests/dev-fct/` — experimental / legacy versions of core functions.
- `tests/tuto-pkg.R` — notes on how the package was scaffolded.

Demo data: `inst/extdata/MAU_Shiny_demo.zip` (current format), `OLAP_Shiny_demo*.zip` (legacy format, plus broken/corrupted variants for error handling).

## Architecture

### Data pipeline (`R/fct_*.R`, exported)

1. `fct_checkzip(.path)` — verifies required files are present (`chain_summary.json`, `SchemaSummary.csv`, `ReportDimensions.csv`, `categories.rds`, `taxonomies.rds` — taxonomies may be missing — and at least one entity table). Detects the entity prefix: `MAU_` (current) or `OLAP_` (legacy).
2. `fct_readzip(.path, .pb_ss, .pb_id)` — reads each file in a `tryCatch` (csv/rds/json), snake_cases the names, and returns `list(data, errors, var_meta, entity_prefix)`. When there are no errors it builds `var_meta` per entity via `fct_varinfo()` and drops rows with `weight == 0`/`NA`. Progress is pushed to a Shiny progress bar when `.pb_ss`/`.pb_id` are given; logs go through `message()` (captured in the UI console).
3. `fct_varinfo(.zip, .entity)` (internal) — builds per-entity column metadata (`report_type` dimension/measure, `dimension_baseunit`, `stratum`, `categoryType` flat/hierarchical, …) by merging the schema summary and the chain's result variables, then filters out multiple, hidden and no-data variables.
4. `fct_arenalyse(.zip, .entity, .dim, .pvalue, .cm, .lonely, ...)` — the estimation engine, organised as numbered steps (coerce inputs → configuration → filter → build `df_total` (with `tidyr::complete()` when some dimensions are below base-unit level) → per-hectare values → survey design (SRS / stratified / cluster) → expansion areas → `survey_mean` → totals → polish → counts). `.cm = "fast"` estimates all measures at once; `"safe"` estimates per measure and keeps partial results. Survey options (lonely PSU) are set locally and restored with `on.exit()`. Returns `list(MEANS, TOTALS)`.
5. `fct_mean()` — small example function.

### Shiny app

- `R/shiny_run_arenalytics.R` — entry point: global options, i18n setup, `bslib` theme, `page_navbar` UI, and the main server. Modules share a single `rv <- reactiveValues(inputs, insights, analysis, actions)`; navigation between tabs is triggered through `rv$actions$*`.
- Modules come in UI/server pairs: `mod_home_*`, `mod_about_*`, `mod_tool_*`. `mod_tool_server.R` (~1150 lines) holds almost all app logic: the sidebar accordions (load → insights → run analysis), insight cards, label replacement for categories/taxonomies, MEANS/TOTALS plots with dimension filters, table export, and report download.
- Result label replacement ("Polish results" step): dimension codes are swapped for taxonomy scientific names or category labels (`label_<lang>` if present, else `label`, keyed on `code_joint`). Category dimensions become factors whose levels follow the category table order (`level_*_code` then `code`), so tables, plots and filters keep the survey's class order; taxonomy dimensions stay character (alphabetical). Convert to character where a plain vector is needed (e.g. filter choices). `tests/check-toolserver.R` mirrors this step.
- `R/mod_tool_server_bkp.R` is an untracked local backup, fully commented out — do not edit it or treat it as live code.
- Reports: `inst/quarto/analysis-report.qmd`, copied to a temp dir and rendered with `quarto::quarto_render()` from the tool server.
- Static assets (`inst/assets`: CSS, JS handlers, logos, favicons) are served under the `assets/` prefix registered in `R/zzz.R` (`.onLoad`).

### Translations

- UI text goes through `shiny.i18n`. Keys are defined in `.tr_keys()` (`R/utils-tr.R`) and each value must exactly match an `en` entry in `inst/assets/translations.json` (which also holds `fr` and `sp`). Use `i18n$t(.tr$key)` in UI code; when adding text, update both files.

### Other

- `R/utils.R` — `%||%` backport, `utils_find_label()`, `utils_make_grp()`.
- `data-raw/make_offline_bundle.R` — builds offline package bundles (see `vignettes/offline-install.Rmd`). Not shipped with the package.

## Coding conventions

### Required style rules

1. **Prefer tidyverse functions over base R equivalents.** In particular, use `purrr::map()` / `map_chr()` / `map_dfr()` / `walk()` etc. instead of the `apply` family (`lapply`, `sapply`, `vapply`, `mapply`, `apply`) and over `for` loops where a functional is natural. Likewise prefer `dplyr`, `tidyr`, `stringr`, `tibble` over base data-frame and string manipulation (`subset`, `merge`, `grepl`, `gsub`, `paste` inside data wrangling, etc.).
2. **Write helper functions only when needed.** Create a helper only if a code block of 5 or more lines is reused more than 4 times. Otherwise keep the code inline where it is used.
3. **Write code that reads chronologically.** Prefer a logical, top-to-bottom sequence of steps (load → prepare → compute → output) over jumping between definitions. Keep steps in the order they execute, use pipes to express a transformation as one readable flow, and avoid forward references to code defined further down.

### Existing conventions to follow

- Always namespace-qualify package calls (`dplyr::filter`, `stringr::str_detect`, …); only `shiny` and `bslib` are imported wholesale. Add new dependencies to `DESCRIPTION` `Imports`.
- Use the native pipe `|>` and the `.data$col` pronoun inside tidy evaluation (needed for R CMD check).
- Function arguments are dot-prefixed (`.path`, `.zip`, `.entity`, `.dim`); exported functions are `fct_*`, modules `mod_<name>_UI` / `mod_<name>_server`, internal helpers `utils_*`.
- Document functions with roxygen2 (markdown enabled); internal ones use `@noRd`. Run `devtools::document()` after changing roxygen tags — never edit `NAMESPACE` or `man/` by hand.
- Section outline (see `R/mod_tool_server.R`): a main section is preceded by 3 empty rows and followed by 1, written as `##` / `## Title ######` / `##`; a subsection is surrounded by empty rows, written as `## + Title ======` (the `+` indents it in the editor outline). Steps inside a function body are plain `## Comment` lines. Module servers are split into main sections by UI area (Accordion, Panel insights, Panel analysis) with one subsection per step. In `fct_*` files, numbered steps `## 1. Step ------`. Older files may still use `## . + Title ----` for a third level.
- Each `fct_*` function starts with a commented `## !!! FOR TESTING ONLY` block setting its arguments to demo values so the body can be run line by line. Keep it updated and commented out.
- Flag workarounds with `## !!! TMP !!!` or `## !!! ... !!!` notes explaining the reason.
- Log progress with `message()` using the `"[%Y-%m-%d %H:%M:%S] text"` format so it shows up in the app's console div.
