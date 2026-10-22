# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

`arenalytics` is an R package that ships a Shiny dashboard ("Analytical Dashboard for Open Foris Arena"). Users upload a ZIP file produced by an Open Foris Arena processing chain; the app checks and reads it, shows survey insights, runs design-based survey estimation (means and totals per reporting dimension, via `srvyr`/`survey`), plots results and exports a Quarto report.

- Name: the app is displayed as **ArenaLytics** (capital L, for easier pronunciation) in all user-facing text, translations and docs prose. The R package, functions, file names, repositories and URLs stay `arenalytics`.
- This repo (`gaelso/arenalytics_dev`) is the development version. Production lives at `openforis/arenalytics`.
- Work happens on `dev`; `master` is the main branch (CI runs R-CMD-check on push/PR to `master`).
- Deployed on shinyapps.io / Posit Connect Cloud via `app.R` + `manifest.json`. Regenerate the manifest with `source("data-raw/write_manifest.R")` after a dependency or asset change: it bundles only the git-tracked `app.R`, `DESCRIPTION`, `NAMESPACE`, `LICENSE`, `R/` and `inst/` (commit new assets first). Do not run a bare `rsconnect::writeManifest()`: it scans `tests/` and `data-raw/` and adds dev packages (devtools, testthat, pkgdown...).
- Licence: MIT, `Copyright (c) 2026 FAO` (`cph` in `DESCRIPTION`). `LICENSE` holds the full MIT text so GitHub detects it; R CMD check therefore gives the expected NOTE "License stub is invalid DCF". The FAO logo and Global Goals identity are not covered by the MIT licence.

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
- `tests/tuto-pkg.R` — notes on how the package was scaffolded, the git workflow, the release steps to `openforis/arenalytics`, and the URLs to update when the app moves to the `un-fao` GitHub, FAO shinyapps.io and Posit Connect Cloud accounts (all commented).

Demo data: `inst/extdata/MAU_Shiny_demo.zip` (current format), `OLAP_Shiny_demo*.zip` (legacy format, plus broken/corrupted variants for error handling).

## Architecture

### Data pipeline (`R/fct_*.R`, exported)

1. `fct_checkzip(.path)` — verifies required files are present (`chain_summary.json`, `SchemaSummary.csv`, `ReportDimensions.csv`, `categories.rds`, `taxonomies.rds` — taxonomies may be missing — and at least one entity table). Detects the entity prefix: `MAU_` (current) or `OLAP_` (legacy).
2. `fct_readzip(.path, .pb_ss, .pb_id)` — reads each file in a `tryCatch` (csv/rds/json), snake_cases the names, and returns `list(data, errors, var_meta, entity_prefix)`. When there are no errors it builds `var_meta` per entity via `fct_varinfo()` and drops rows with `weight == 0`/`NA`. Progress is pushed to a Shiny progress bar when `.pb_ss`/`.pb_id` are given; logs go through `message()` (captured in the UI console).
3. `fct_varinfo(.zip, .entity)` (internal) — builds per-entity column metadata (`report_type` dimension/measure, `dimension_baseunit`, `stratum`, `categoryType` flat/hierarchical, …) by merging the schema summary and the chain's result variables, then filters out multiple, hidden and no-data variables.
4. `fct_arenalyse(.zip, .entity, .dim, .pvalue, .cm, .lonely, ...)` — the estimation engine, organised as numbered steps (coerce inputs → configuration → filter → build `df_total` (with `tidyr::complete()` when some dimensions are below base-unit level) → per-hectare values → survey design (SRS / stratified / cluster) → expansion areas → `survey_mean` → totals → polish → counts). `.cm = "fast"` estimates all measures at once; `"safe"` estimates per measure and keeps partial results. Survey options (lonely PSU) are set locally and restored with `on.exit()`. Returns `list(MEANS, TOTALS)`.
5. `fct_mean()` — small example function.

### Shiny app

- `R/shiny_run_arenalytics.R` — entry point: global options, i18n setup, `bslib` theme, `page_navbar` UI, and the main server. Modules share a single `rv <- reactiveValues(inputs, insights, analysis, actions, ui)`; navigation between tabs is triggered through `rv$actions$*`, and `rv$ui$dark_mode` ("light"/"dark", from the navbar toggle `input$dark_mode`) lets modules adapt outputs drawn in R.
- Modules come in UI/server pairs: `mod_home_*`, `mod_about_*`, `mod_tool_*`. `mod_tool_server.R` (~1150 lines) holds almost all app logic: the sidebar accordions (1 load ZIP file → 2 select inputs: analysis type, entity, dimensions → 3 configure analysis: lonely PSU, computation mode, confidence level, run), insight cards, label replacement for categories/taxonomies, one figure and one table following the "Estimates" selector (means or totals) with dimension filters, table export, and report download. Figures are built in a light and a dark version (`plot_colors`): the panel stacks both outputs and CSS shows the one of the current theme (`.plot-themed`, instant toggle), the PNG download offers a Light/Dark switch, and the report always uses the light one.
- Result label replacement ("Polish results" step): dimension codes are swapped for taxonomy scientific names or category labels (`label_<lang>` if present, else `label`, keyed on `code_joint`). Category dimensions become factors whose levels follow the category table order (`level_*_code` then `code`), so tables, plots and filters keep the survey's class order; taxonomy dimensions stay character (alphabetical). Convert to character where a plain vector is needed (e.g. filter choices). `tests/check-toolserver.R` mirrors this step.
- About page (`mod_about_UI.R`): workflow (four steps, then buttons for the detailed workflow, a Bootstrap modal in the UI markup, and the ArenaLytics section of the Arena user manual), demo dataset (download from `mod_about_server.R`, summary and data overview cards describing `inst/extdata/MAU_Shiny_demo.zip`: update them if the demo changes), context (Open Foris, Open Foris Arena, ArenaLytics), under the hood (package card with the version from `utils::packageVersion()`, dependencies, latest developments until the last month, linking to the full list in `vignettes/latest-developments.Rmd` (update both when releasing), and use cases and stories, a placeholder for links to info notes and stories). All text is in `.tr$about_*` keys; styles are the `.about-*` classes in `style.css`.
- Reports: `inst/quarto/analysis-report.qmd`, copied to a temp dir and rendered with `quarto::quarto_render()` from the tool server.
- Static assets (`inst/assets`: CSS, JS handlers, fonts, branding files) are served under the `assets/` prefix registered in `R/zzz.R` (`.onLoad`). CSS and JS are linked with a `?v=<asset_v>` cache-busting stamp (latest modification time in `inst/assets`); keep it when adding a stylesheet or script.

### Branding and styling

The app follows the FAO Design System (v3.7.2), the FAO Logo Policy and the FAO Global Goals visual identity guidelines. The reference documents are FAO-internal: keep them out of the repo (`tests/branding/` is gitignored) and never quote them in code, comments or docs.

- **Theme:** `bs_theme()` with the Yeti bootswatch; Open Sans for text and Fira Code for code, self-hosted in `inst/assets/fonts/` (`data-raw/vendor_fonts.R`).
- **Colours, one source:** the `app_colors` list (light/dark) in `R/shiny_run_arenalytics.R`. Each entry becomes a CSS variable `--app-<name>` (underscores → hyphens) for `:root` and `[data-bs-theme=dark]`; the light values also feed `bs_theme()`. In `inst/assets/style.css` use these variables, not hex codes. Entries: `primary`/`link` (FAO blue, lighter link in dark), `secondary`/`success` (Open Foris green), `secondary_tint` (accordion headers), `info`, `warning`/`danger` (FAO orange/red, identical in both themes), `link_hover` (FAO greys), `btn_primary`/`btn_primary_hover` (FAO primary button), `card_header` (FAO Primary Light).
- **Header:** official FAO 3-line English logo for all languages, 48 px, top left, not a link, light/dark files swapped by CSS (`.header-logo-light` / `.header-logo-dark`); then the two-line app title linking home (`{ArenaLytics}` over `.tr$app_title`). Fixed 72 px navbar, `navbar-expand-xl`. Logo files in `inst/assets/branding/` are used unmodified (see its README).
- **Footer:** `app_footer()` — Global Goals icons (`.gg-logo-light` / `.gg-logo-dark`, 60 px), six fao.org links whose URLs follow the language (`data-href-<lang>`), app credit with `utils::packageVersion()`, © FAO.
- **`inst/assets/js_brand.js`:** handles the `app-locale` message sent on language change (sets `<html lang>`, swaps `data-src-<lang>` / `data-alt-<lang>` / `data-href-<lang>`), and swaps the favicon (black / white `.ico`) with the browser theme.
- **Links:** text links in panels and the footer use the body colour, underlined, grey on hover (`--app-link-hover`). External links open in a new tab (`target = "_blank"`).
- **Buttons:** every action and download button is `btn-primary` (FAO blue, lighter on hover). `fileInput()`'s "Browse..." button is made primary with `htmltools::tagQuery()`. Home page buttons add `btn-icon` and a `bsicons::bs_icon("chevron-right")` after the label.
- **Toggles (shinyWidgets):** a custom `status` gives the class `btn-<status>`.
  - Segmented switch for one choice: `radioGroupButtons(status = "segment", size = "sm", justified = TRUE)` inside `div(class = "seg-control")`; add `seg-inline` (and `label = NULL`) when it sits on one line with a button.
  - Chips for several choices: `checkboxGroupButtons(status = "chip", individual = TRUE, checkIcon = list(yes = bsicons::bs_icon("check-lg")))` inside `div(class = "chip-group")`.
  - With Bootstrap 5, shinyWidgets renders a hidden `input.btn-check` followed by `label.btn`: style the selected option with `.btn-check:checked + .btn`, not `.active`. Avoid `status = "default"`: bslib's `.btn-default` rule overrides custom styles.
- **Cards and sidebar:** cards have a 0.5rem radius and `--app-card-header` headers; the sidebar has no background (`--bslib-sidebar-bg: transparent`); accordion headers keep the green tint.
- **Info notes:** `div(class = "text-info", style = "font-size: 0.85em; font-style: italic; ...", bsicons::bs_icon("info-circle"), " ", text)`. Notes that depend on an input use `conditionalPanel()`; in the sidebar it renders with `display: contents`, so put the class and style on an inner `div`.

### Translations

- UI text goes through `shiny.i18n`. Keys are defined in `.tr_keys()` (`R/utils-tr.R`) and each value must exactly match an `en` entry in `inst/assets/translations.json` (which also holds `fr` and `sp`). Use `i18n$t(.tr$key)` in UI code; when adding text, update both files.

### Other

- `R/utils.R` — `%||%` backport, `utils_find_label()`, `utils_make_grp()`.
- README images (screenshots) go in `man/figures/` (excluded from the package build in `.Rbuildignore`, copied to the docs site by pkgdown); not in `inst/`, which ships with the package.
- Vignettes (pkgdown articles, listed in `_pkgdown.yml`): `user-guide.Rmd` (summary of the ArenaLytics section of the Arena user manual), `offline-install.Rmd`, `latest-developments.Rmd`. The site at openforis.github.io/arenalytics is built by `.github/workflows/pkgdown.yaml` on each push to `master` of `openforis/arenalytics`.
- `data-raw/` (not shipped with the package): `make_offline_bundle.R` builds offline package bundles (see `vignettes/offline-install.Rmd`; its package list mirrors `DESCRIPTION` `Imports`), `write_manifest.R` regenerates `manifest.json`, `vendor_fonts.R` and `vendor_flags.R` download the self-hosted fonts and language selector flags (the app loads no CDN asset, so it works offline).

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
- Keep R source files ASCII (R CMD check): write non-ASCII characters in strings as escapes (`"\u00e9"`, `"\u00a9"`). Translated text belongs in `translations.json`, which is UTF-8.
