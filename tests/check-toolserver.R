# ## Non-interactive version of mod_tool_server() (R/mod_tool_server.R)
# ##
# ## Same steps and code as the module, with the Shiny parts removed:
# ## - input and rv are plain lists, set manually in SETTINGS
# ## - reactives are plain objects computed in order
# ## - UI outputs (shinyjs, progress bars, renderUI, DT, clipboard) are printed instead
# ## - downloads and report are written to out_dir when save_outputs is TRUE
# ##
# ## Run line by line after changing SETTINGS, e.g. to inspect what goes into x_dim for the plot.

# devtools::load_all()



# ##
# ## SETTINGS ######
# ##

# rv <- list(
#   inputs   = list(),
#   insights = list(),
#   analysis = list(),
#   actions  = list(),
#   ui       = list(dark_mode = "light") ## "dark" to check the dark figures
# )

# input <- list()

# ## + Data ======

# input$load_zip$datapath <- "inst/extdata/MAU_Shiny_demo.zip"
# # input$load_zip$datapath <- "data-raw/MAU_Shiny_(plot_as_baseunit-NO_TAXON).zip"


# ## + APP code ======

# save_outputs <- FALSE ## TRUE writes table CSV, plot PNGs and report to out_dir
# out_dir      <- file.path(tempdir(), "arenalytics-check")
# input$analysis_report_format <- "docx" ## "html" or "docx"



# ##
# ## ACCORDION ######
# ##

# ## + ACC1: Load data ======

# ## ++ Check data file on load ------

# rv$inputs$pathzip  <- input$load_zip$datapath
# rv$inputs$checkzip <- fct_checkzip(.path = rv$inputs$pathzip)

# rv$inputs$checkzip$all_ok
# if (!rv$inputs$checkzip$all_ok | !rv$inputs$checkzip$has_taxonomies) {
#   cat("Missing files:\n", paste(rv$inputs$checkzip$missing, collapse = ", "))
# }

# ## ++ Read data on button read ------

# ## +++
# tmp_out <- fct_readzip(.path = rv$inputs$pathzip)
# ## +++

# ## Reproducible error: specific to asic example
# # tmp_out$data$MAU_tree <- tmp_out$data$MAU_tree |> dplyr::mutate(tree_biomass_ag_chave = tree_biomass_ag * 0.95)
# # row_chave <- tmp_out$var_meta$tree |>
# #   dplyr::filter(name == "tree_biomass_ag") |>
# #   dplyr::mutate(
# #     name = "tree_biomass_ag_chave",
# #     label = paste(label, "Chave", sep = " ")
# #     )
# # tmp_out$var_meta$tree <- dplyr::bind_rows(tmp_out$var_meta$tree, row_chave)

# ## Assign the function output to rv$inputs
# rv$inputs <- purrr::list_assign(rv$inputs, !!!tmp_out)

# rv$inputs$data_ok <- !is.null(rv$inputs$data) && length(rv$inputs$errors) == 0
# rv$inputs$data_ok
# names(rv$inputs$data)

# ## + ACC2: Entities ======

# ## Convention entities = 'tree' etc., entities_labs = 'Tree'
# rv$insights$entities <- names(rv$inputs$data) |>
#   stringr::str_subset(rv$inputs$checkzip$entity_prefix) |>
#   stringr::str_remove(rv$inputs$checkzip$entity_prefix)

# entity_lang <- rv$inputs$data$schema_summary |>
#   dplyr::as_tibble() |>
#   dplyr::filter(.data$type == "entity") |>
#   dplyr::select("name", dplyr::starts_with("label"))

# rv$insights$entities_labs <- utils_find_label(
#   .df = entity_lang,
#   .name = rv$insights$entities,
#   .lang = rv$inputs$data$chain_summary$selectedLanguage
# )
# rv$insights$entities_named <- purrr::set_names(rv$insights$entities, rv$insights$entities_labs)
# rv$insights$entities_named

# ## ++ Prepare dimensions for selected entity ------
# input$analysis_sel_entity <- "tree"

# rv$analysis$dim_meta <- rv$inputs$var_meta[[input$analysis_sel_entity]]

# ## !!! TO INSPECT FURTHER !!!
# strat_row <- rv$analysis$dim_meta |> dplyr::filter(.data$stratum)
# rv$analysis$strat_label <- if (nrow(strat_row) > 0) strat_row$label[1] else NULL

# ## ++ Dimension choices (base-unit then sub-unit) ------

# ## Available values for input$analysis_bu_dims and input$analysis_sub_dims
# choose_dim    <- utils_make_grp(.rv = rv, .is_bu = TRUE)
# choose_dim
# choose_subdim <- utils_make_grp(.rv = rv, .is_bu = FALSE)
# choose_subdim

# ## Make wrong DBH class to arrange sorting
# names(rv$inputs$data$categories$tree_dbh_10)
# rv$inputs$data$categories$tree_dbh_10 <- rv$inputs$data$categories$tree_dbh_10 |>
#   dplyr::mutate(label_en = dplyr::case_when(
#     label_en == "10-19.9 cm" ~ "9.99-19.9 cm",
#     TRUE ~ label    
#   ))
# rv$inputs$data$categories$tree_dbh_10


# ##
# ## GET INPUTS FOR THE PLOT AND TABLES ######
# ##

# input$analysis_mode     <- "other"  ## "area" or "other"
# input$analysis_bu_dims  <- c("plot_landuse")
# input$analysis_sub_dims <- c("tree_dbh_10cm")


# input$analysis_p_value      <- "0.95"
# input$analysis_compute_mode <- "safe"   ## "fast" or "safe"
# input$analysis_lonely_psu   <- "adjust" ## "adjust" or "remove"

# ## + Results and plot ======

# ## NULL = app default (first measure / first dim / MEANS)
# input$analysis_sel_measure <- "tree_count"
# input$analysis_table_source <- "MEANS"
# input$plot_dim              <- "tree_dbh_10cm"
# input$plot_fill             <- "" ## "" for none
# input$plot_facet            <- "plot_landuse" ## "" for none
# input$plot_errbar           <- TRUE
# input$plot_flip             <- FALSE
# input$plot_wrap_labels      <- TRUE
# input$plot_hide_legend      <- FALSE
# input$plot_download_theme   <- "light" ## "dark" for the dark PNG

# ## Dimension filters: input$filter_dim__<dim> <- c("class label", ...); NULL = no filter
# # input$filter_dim__tree_health <- c("Healthy")

# ## ++ Selected dimensions ------

# rv$analysis$dims_sel <- if (identical(input$analysis_mode, "area")) {
#   input$analysis_bu_dims
# } else {
#   c(input$analysis_bu_dims, input$analysis_sub_dims)
# }
# rv$analysis$dims_sel

# ## ++ Too-many-dims warning and stratum note ------

# if (length(rv$analysis$dims_sel) > 4) message("More than 4 dimensions selected, computation may be slow.")
# if (!identical(input$analysis_mode, "area") && !is.null(rv$analysis$strat_label)) {
#   message("'", rv$analysis$strat_label, "' is used for stratification.")
# }

# ## + ACC3: Run analysis =======

# is_area <- identical(input$analysis_mode, "area")

# ## Measures info for plot selector
# rv$analysis$measures_meta <- if (is_area) {
#   tibble::tibble(name = "area", label = "Area")
# } else {
#   rv$inputs$var_meta[[input$analysis_sel_entity]] |>
#     dplyr::filter(.data$report_type == "measure")
# }

# ## ++ Compute results ------

# ## Area mode: sum of expansion factors per base-unit dimensions
# ## Other measures: survey estimation with fct_arenalyse()
# result <- if (is_area) {

#   base_uuid <- paste0(rv$inputs$data$chain_summary$baseUnit, "_uuid")

#   area_df <- rv$inputs$data[[paste0(rv$inputs$checkzip$entity_prefix, input$analysis_sel_entity)]] |>
#     tibble::as_tibble() |>
#     dplyr::rename(dplyr::any_of(c(mau_baseunit_total = "OLAP_baseunit_total"))) |>
#     dplyr::filter(.data$mau_baseunit_total == TRUE, .data$weight > 0, .data$exp_factor_ != 0) |>
#     dplyr::mutate(dplyr::across(dplyr::all_of(rv$analysis$dims_sel), as.character)) |>
#     dplyr::select(dplyr::all_of(c(base_uuid, rv$analysis$dims_sel)), "exp_factor_") |>
#     dplyr::distinct() |>
#     dplyr::summarise(area = sum(.data$exp_factor_), .by = dplyr::all_of(rv$analysis$dims_sel))

#   list(MEANS = area_df, TOTALS = area_df)

# } else {

#   ## +++
#   fct_arenalyse(
#     .zip    = rv$inputs,
#     .entity = input$analysis_sel_entity,
#     .dim    = rv$analysis$dims_sel,
#     .pvalue = as.numeric(input$analysis_p_value),
#     .cm     = input$analysis_compute_mode,
#     .lonely = input$analysis_lonely_psu
#   )
#   ## +++

# }

# ## ++ Polish results ------

# ## Replace dimension codes with labels: scientific names for taxonomies,
# ## category labels otherwise. Then drop technical columns and move counts last.
# label_col <- paste0("label_", rv$inputs$data$chain_summary$selectedLanguage)
# dim_meta  <- rv$analysis$dim_meta |> dplyr::filter(.data$report_type == "dimension")
# cats      <- rv$inputs$data$categories
# taxos     <- rv$inputs$data$taxonomies %||% list()
# cols_drop <- if (is_area) character(0) else c("area", "JOIN_COL")

# rv$analysis$result <- purrr::map(result, \(df) {
#   intersect(dim_meta$name, names(df)) |>
#     purrr::reduce(\(acc, col) {
#       cat_name <- dim_meta |> dplyr::filter(.data$name == col) |> dplyr::pull("categoryName") |> dplyr::first()
#       if (is.na(cat_name) || !nzchar(cat_name)) return(acc)

#       taxo_tbl <- taxos[[cat_name]]
#       cat_tbl  <- cats[[cat_name]]

#       is_taxo <- !is.null(taxo_tbl) && "scientific_name" %in% names(taxo_tbl)

#       ## Category lookup in category order: by parent codes for hierarchical categories, then code
#       lookup <- if (is_taxo) {
#         purrr::set_names(as.character(taxo_tbl$scientific_name), as.character(taxo_tbl$code))
#       } else if (!is.null(cat_tbl)) {
#         lbl_col <- if (label_col %in% names(cat_tbl)) label_col else "label"
#         cat_tbl <- cat_tbl |> dplyr::arrange(dplyr::across(dplyr::matches("^level_\\d+_code$")), .data$code)
#         ## !!! Replaced code with code_joint, should solve multi-level cats
#         purrr::set_names(as.character(cat_tbl[[lbl_col]]), as.character(cat_tbl$code_joint))
#       }
#       if (is.null(lookup)) return(acc)

#       acc <- acc |>
#         dplyr::mutate(!!col := dplyr::coalesce(unname(lookup[as.character(.data[[col]])]), as.character(.data[[col]])))
#       if (is_taxo) return(acc)

#       ## Category labels as factors to keep category order in tables and plots
#       acc |>
#         dplyr::mutate(!!col := factor(.data[[col]], levels = unique(c(unname(lookup), sort(unique(.data[[col]]))))))
#     }, .init = df) |>
#     dplyr::select(-dplyr::any_of(cols_drop)) |>
#     dplyr::relocate(dplyr::any_of(c("item_count", "base_unit_count", "cluster_count")), .after = dplyr::last_col())
# })

# rv$analysis$dims   <- rv$analysis$dims_sel
# rv$analysis$entity <- input$analysis_sel_entity
# rv$analysis$mode   <- input$analysis_mode

# rv$analysis$result



# ##
# ## PANEL INSIGHTS ######
# ##

# ## + Survey info ======

# ch     <- rv$inputs$data$chain_summary
# lang   <- ch$selectedLanguage %||% "en"
# schema <- tibble::as_tibble(rv$inputs$data$schema_summary)

# ## Sampling strategy code → human-readable name
# sampling_strategy_labels <- c(
#   "1" = "Random Sampling",
#   "2" = "Systematic Sampling",
#   "3" = "Stratified Random Sampling",
#   "4" = "Stratified Systematic Sampling",
#   "5" = "Two-phase Sampling"
# )
# strat_name <- dplyr::coalesce(
#   unname(sampling_strategy_labels[as.character(ch$samplingStrategy %||% "")]), "Unknown"
# )

# ## Stratification attribute label
# stratum_raw <- ch$stratumAttribute %||% ""
# stratum_label <- if (nzchar(stratum_raw)) {
#   paste0(utils_find_label(schema, stratum_raw, lang), " [", stratum_raw, "]")
# } else {
#   "-"
# }

# ## Clustering variable labels
# is_clustered <- nzchar(ch$clusteringEntity %||% "")
# cluster_attr <- if (is_clustered) {
#   keys   <- ch$clusteringEntityKeys %||% character(0)
#   labels <- utils_find_label(schema, keys, lang)
#   paste(paste0(labels, " [", keys, "]"), collapse = ", ")
# } else {
#   "-"
# }

# survey_name <- paste0(ch$surveyLabel %||% ch$surveyName, " [", ch$surveyName, "]")

# info_rows <- c(
#   "Survey"                       = survey_name,
#   "Cycle"                        = ch$selectedCycle %||% "-",
#   "Sampling strategy"            = strat_name,
#   "Stratification attribute"     = stratum_label,
#   "Clustering"                   = if (is_clustered) "Yes" else "No",
#   "Clustering entity"            = cluster_attr,
#   "Non-response bias correction" = if (isTRUE(ch$nonResponseBiasCorrection)) "Yes" else "No"
# )
# tibble::enframe(info_rows, name = "item", value = "value")

# ## + Current selection ======

# selected_dims <- c(input$analysis_bu_dims, input$analysis_sub_dims)

# ## Resolve dimension codes → labels from dim_meta
# dim_labels <- if (!is.null(rv$analysis$dim_meta) && length(selected_dims) > 0) {
#   dplyr::coalesce(rv$analysis$dim_meta$label[match(selected_dims, rv$analysis$dim_meta$name)], selected_dims)
# } else {
#   selected_dims
# }

# ## Resolve entity code → label
# entity_label <- rv$insights$entities_named[rv$insights$entities_named == input$analysis_sel_entity]
# entity_label <- if (length(entity_label) > 0) names(entity_label)[1] else input$analysis_sel_entity

# c(
#   "Entity"              = if (!is_area) entity_label else "-",
#   "Analysis type"       = if (is_area) "Area" else "Other measures",
#   "Selected dimensions" = if (length(dim_labels) == 0) "No dimensions selected." else paste(dim_labels, collapse = ", ")
# ) |>
#   tibble::enframe(name = "item", value = "value")

# ## + Selected entity data, dims and measures ======

# insight_ctx <- list(
#   dim_meta     = rv$inputs$var_meta[[input$analysis_sel_entity]],
#   entity_table = rv$inputs$data[[paste0(rv$inputs$checkzip$entity_prefix, input$analysis_sel_entity)]] |>
#     tibble::as_tibble(),
#   dims = list(
#     bu  = input$analysis_bu_dims %||% character(0),
#     sub = if (is_area) character(0) else input$analysis_sub_dims %||% character(0)
#   ),
#   meas_meta = if (is_area) {
#     tibble::tibble(name = "area", label = "Area")
#   } else {
#     rv$inputs$var_meta[[input$analysis_sel_entity]] |> dplyr::filter(.data$report_type == "measure")
#   }
# )

# ## + Base-unit and sub-unit dimension classes ======

# ## One row per selected dim: empty class / NA flags and classes with category labels
# insight_dims <- purrr::map(c(bu = "bu", sub = "sub"), \(grp) {
#   purrr::map(insight_ctx$dims[[grp]], \(v) {
#     meta_row   <- insight_ctx$dim_meta |> dplyr::filter(.data$name == v) |> dplyr::slice(1)
#     cat_name   <- meta_row$categoryName[[1]]
#     values_raw <- insight_ctx$entity_table[[v]]

#     ## Unique non-missing classes, with category labels when available
#     values <- values_raw |>
#       as.character() |>
#       stringr::str_subset(".") |>
#       unique() |>
#       sort()

#     cat_tbl <- if (!is.na(cat_name) && nzchar(cat_name)) rv$inputs$data$categories[[cat_name]]

#     if (!is.null(cat_tbl)) {
#       cat_tbl   <- tibble::as_tibble(cat_tbl)
#       label_col <- paste0("label_", lang)
#       lbl_col   <- if (label_col %in% names(cat_tbl)) label_col else "label"
#       lookup    <- purrr::set_names(as.character(cat_tbl[[lbl_col]]), as.character(cat_tbl$code))
#       values    <- dplyr::coalesce(unname(lookup[values]), values)
#     }

#     tibble::tibble(
#       name        = v,
#       label       = meta_row$label[[1]],
#       empty_class = any(!is.na(values_raw) & values_raw == ""),
#       na_present  = any(is.na(values_raw)),
#       classes     = paste(values, collapse = ", ")
#     )
#   }) |>
#     purrr::list_rbind()
# })
# insight_dims

# ## + Measures ======

# insight_ctx$meas_meta$label



# ##
# ## PANEL ANALYSIS ######
# ##

# ## + Layout by analysis mode (area mode has no means) ======

# if (is_area) input$analysis_table_source <- "TOTALS"
# input$analysis_table_source <- input$analysis_table_source %||% "MEANS"

# ## + Plot selectors ======

# dim_meta_sel <- rv$analysis$dim_meta |> dplyr::filter(.data$name %in% rv$analysis$dims)
# dim_choices  <- purrr::set_names(dim_meta_sel$name, dim_meta_sel$label)
# meas_choices <- purrr::set_names(rv$analysis$measures_meta$name, rv$analysis$measures_meta$label)

# ## Available choices, app defaults when not set in SETTINGS
# dim_choices
# meas_choices
# input$analysis_sel_measure <- input$analysis_sel_measure %||% unname(meas_choices[1])
# input$plot_dim             <- input$plot_dim   %||% unname(dim_choices[1])
# input$plot_fill            <- input$plot_fill  %||% ""
# input$plot_facet           <- if (length(dim_choices) >= 2) input$plot_facet %||% "" else ""

# ## + Selected measure ======

# measure_name <- input$analysis_sel_measure %||% dplyr::first(rv$analysis$measures_meta$name)
# meas_row     <- rv$analysis$measures_meta |> dplyr::filter(.data$name == measure_name)

# sel_measure <- list(
#   name  = measure_name,
#   label = dplyr::first(meas_row$label),
#   unit  = if ("unit" %in% names(meas_row)) dplyr::first(meas_row$unit) else NA_character_
# )
# sel_measure

# ## + Dimension filters ======

# ## Classes available for each input$filter_dim__<dim>
# purrr::map(purrr::set_names(rv$analysis$dims), \(d) as.character(sort(unique(rv$analysis$result$MEANS[[d]]))))

# ## Current filter values for all dims, named by dim
# filter_vals <- purrr::map(
#   purrr::set_names(rv$analysis$dims %||% character(0)),
#   \(d) input[[paste0("filter_dim__", d)]]
# )
# filter_vals

# ## + Filtered results ======

# ## MEANS and TOTALS with dimension filters applied
# filters <- purrr::compact(filter_vals)

# analysis_filtered <- purrr::map(rv$analysis$result, \(df) {
#   purrr::reduce(names(filters), \(acc, d) dplyr::filter(acc, .data[[d]] %in% filters[[d]]), .init = df)
# })
# analysis_filtered

# ## + Output table ======

# ## Dims, other columns, selected measure columns then counts, with labels as column names
# df            <- analysis_filtered[[input$analysis_table_source]]
# measure       <- sel_measure
# measure_names <- rv$analysis$measures_meta$name
# dim_names     <- rv$analysis$dims %||% character(0)
# count_cols    <- intersect(c("item_count", "base_unit_count", "cluster_count"), names(df))

# ## !!! Solved nested col names being selected.
# nested_measures <- measure_names |>
#   setdiff(measure$name) |>
#   purrr::keep(\(m) stringr::str_starts(m, measure$name))

# measure_cols <- names(df) |>
#   purrr::keep(\(x) stringr::str_starts(x, measure$name)) |>
#   purrr::discard(\(x) length(nested_measures) > 0 && any(stringr::str_starts(x, nested_measures)))

# all_measure_cols <- purrr::map(measure_names, \(m) stringr::str_subset(names(df), paste0("^", m, "($|_)"))) |>
#   unlist()
# other_cols <- setdiff(names(df), c(dim_names, count_cols, all_measure_cols))

# ## Column labels, first match wins: dimensions, fixed columns, selected measure
# ## !!! ERROR HERE IF 2 VARS HAVE SAME NAME AND ONE IS EXTENDED !!!
# dim_meta <- rv$analysis$dim_meta |> dplyr::filter(.data$report_type == "dimension")
# col_labels <- c(
#   purrr::set_names(dim_meta$label, dim_meta$name),
#   area            = "Area",
#   item_count      = "Item count",
#   base_unit_count = "Base unit count",
#   cluster_count   = "Cluster count",
#   purrr::set_names(
#     paste0(measure$label, c("", " (SE)", " (Lower CI)", " (Upper CI)")),
#     paste0(measure$name,  c("", "_se",  "_low",        "_upp"))
#   )
# )

# analysis_table <- df |>
#   dplyr::select(dplyr::all_of(unique(c(dim_names, other_cols, measure_cols, count_cols)))) |>
#   purrr::set_names(\(cols) dplyr::coalesce(unname(col_labels[cols]), cols))
# analysis_table

# ## + Plot validation ======

# ## A plot is valid when every analysis dim is either used in the plot
# ## (x axis, fill or facet) or filtered down to a single class.
# role_dims    <- c(input$plot_dim, input$plot_fill, input$plot_facet) |> stringr::str_subset(".") |> unique()
# invalid_dims <- setdiff(rv$analysis$dims, role_dims) |>
#   purrr::discard(\(d) length(filter_vals[[d]]) == 1)

# plot_validation <- if (length(invalid_dims) == 0) {
#   list(ok = TRUE, message = NULL)
# } else {
#   list(
#     ok = FALSE,
#     message = paste0(
#       "To display the figure, assign these dimensions to Group by or Facet by in ",
#       "Figure options, or filter them to one class: ",
#       rv$analysis$dim_meta |>
#         dplyr::filter(.data$name %in% invalid_dims) |>
#         dplyr::pull("label") |>
#         paste(collapse = ", "),
#       "."
#     )
#   )
# }
# plot_validation

# ## + Plots ======

# if (!plot_validation$ok) stop(plot_validation$message)

# ## Bar plots of MEANS and TOTALS
# dim_meta  <- rv$analysis$dim_meta
# measure   <- sel_measure
# x_dim     <- input$plot_dim
# fill_col  <- input$plot_fill
# facet_col <- input$plot_facet
# use_fill  <- shiny::isTruthy(fill_col)  && fill_col  != ""
# use_facet <- shiny::isTruthy(facet_col) && facet_col != ""
# wrap      <- isTRUE(input$plot_wrap_labels)
# flip      <- isTRUE(input$plot_flip)
# low_col   <- paste0(measure$name, "_low")
# upp_col   <- paste0(measure$name, "_upp")

# ## Inspect plot inputs
# x_dim
# unique(analysis_filtered$MEANS[[x_dim]])

# ## Axis and legend labels
# x_label    <- dim_meta |> dplyr::filter(.data$name == x_dim) |> dplyr::pull("label") |> dplyr::first()
# y_label    <- measure$label
# fill_label <- if (use_fill) dim_meta |> dplyr::filter(.data$name == fill_col) |> dplyr::pull("label") |> dplyr::first()

# if (wrap) {
#   x_label    <- stringr::str_wrap(x_label, width = 28)
#   y_label    <- stringr::str_wrap(y_label, width = 28)
#   fill_label <- if (use_fill) stringr::str_wrap(fill_label, width = 24)
# }
# tick_labels <- if (wrap) scales::label_wrap(18) else ggplot2::waiver()

# ## Unit for plot titles
# unit_txt <- if (!is.na(measure$unit) && nzchar(measure$unit)) measure$unit else NULL

# ## Light and dark versions: the panel shows the current theme, exports use light
# plot_colors <- list(
#   light = list(bg = "white",   text = "grey20",  grid = "grey92",  bar = "grey70", bar_line = "grey30", errbar = "black"),
#   dark  = list(bg = "#222222", text = "#dee2e6", grid = "#3a3f44", bar = "grey45", bar_line = "grey75", errbar = "#dee2e6")
# )

# ## Bars: dodged and colored by fill dim, or plain grey
# bar_pos <- if (use_fill) ggplot2::position_dodge(width = 0.9, preserve = "single") else "identity"
# base_aes <- if (use_fill) {
#   ggplot2::aes(x = .data[[x_dim]], y = .data[[measure$name]], fill = .data[[fill_col]])
# } else {
#   ggplot2::aes(x = .data[[x_dim]], y = .data[[measure$name]])
# }

# analysis_plots <- purrr::map(plot_colors, \(pal) {
#   purrr::map(c(MEANS = "MEANS", TOTALS = "TOTALS"), \(src) {
#     df <- analysis_filtered[[src]]

#     plot_title <- if (src == "MEANS") {
#       if (!is.null(unit_txt)) paste0("Aggregated means (", unit_txt, "/ha)") else "Aggregated means"
#     } else {
#       if (!is.null(unit_txt)) paste0("Aggregated totals (", unit_txt, ")") else "Aggregated totals"
#     }

#     p <- ggplot2::ggplot(df, base_aes) +
#       (if (use_fill) {
#         ggplot2::geom_col(position = bar_pos, col = pal$bar_line)
#       } else {
#         ggplot2::geom_col(position = bar_pos, col = pal$bar_line, fill = pal$bar)
#       }) +
#       ggplot2::labs(x = x_label, y = y_label, fill = fill_label, title = plot_title) +
#       ggplot2::theme_minimal() +
#       ggplot2::theme(
#         plot.background  = ggplot2::element_rect(fill = pal$bg, colour = NA),
#         panel.grid       = ggplot2::element_line(colour = pal$grid),
#         text             = ggplot2::element_text(colour = pal$text),
#         axis.text.x = ggplot2::element_text(size = 12, angle = 45, hjust = 1, colour = pal$text),
#         axis.text.y = ggplot2::element_text(size = 12, colour = pal$text),
#         axis.title.x = ggplot2::element_text(size = 14, margin = ggplot2::margin(t = 10)),
#         axis.title.y = ggplot2::element_text(size = 14, margin = ggplot2::margin(r = 10)),
#         legend.title = ggplot2::element_text(size = 13),
#         legend.text = ggplot2::element_text(size = 11),
#         strip.text = ggplot2::element_text(size = 12, face = "bold", colour = pal$text)
#       ) +
#       ggplot2::scale_x_discrete(
#         labels = tick_labels,
#         # Reverse order when flipped so first item appears at top (not bottom)
#         limits = if (flip) rev else NULL
#       )

#     if (use_fill) {
#       p <- p + ggplot2::scale_fill_discrete(labels = tick_labels)
#     }

#     if (isTRUE(input$plot_errbar) && all(c(low_col, upp_col) %in% names(df))) {
#       p <- p + ggplot2::geom_errorbar(
#         ggplot2::aes(ymin = .data[[low_col]], ymax = .data[[upp_col]]),
#         position = bar_pos,
#         width    = 0.2,
#         col      = pal$errbar
#       )
#     }

#     if (use_facet) {
#       p <- p + ggplot2::facet_wrap(
#         ggplot2::vars(!!rlang::sym(facet_col)),
#         labeller = ggplot2::labeller(.default = ggplot2::label_wrap_gen(width = 18))
#       )
#     }

#     if (flip) {
#       p <- p + ggplot2::coord_flip()
#     }

#     if (isTRUE(input$plot_hide_legend)) {
#       p <- p + ggplot2::theme(legend.position = "none")
#     }

#     if (src == "TOTALS") {
#       p <- p + ggplot2::scale_y_continuous(labels = scales::comma)
#     }

#     p
#   })
# })

# ## Figure of the selected estimates, in the current theme
# analysis_plots[[rv$ui$dark_mode]][[input$analysis_table_source]]

# ## + Download file names ======

# ## File names prefix: AA-<survey-name>-
# survey_stub <- (rv$inputs$data$chain_summary$surveyName %||% "survey") |>
#   stringr::str_replace_all("[^A-Za-z0-9]+", "-") |>
#   stringr::str_remove_all("(^-+|-+$)") |>
#   tolower()
# download_prefix <- paste0("AA-", survey_stub, "-")
# download_prefix

# ## + Table CSV and plot PNG downloads ======

# if (save_outputs) {
#   dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

#   utils::write.csv(
#     analysis_filtered[[input$analysis_table_source]],
#     file.path(out_dir, paste0(download_prefix, "full-table.csv")),
#     row.names = FALSE
#   )
#   if (!is_area) {
#     ggplot2::ggsave(
#       file.path(out_dir, paste0(download_prefix, "fig-mean.png")),
#       plot = analysis_plots$light$MEANS, width = 10, height = 6, dpi = 300
#     )
#   }
#   ggplot2::ggsave(
#     file.path(out_dir, paste0(download_prefix, "fig-total.png")),
#     plot = analysis_plots$light$TOTALS, width = 10, height = 6, dpi = 300
#   )
# }

# ## + Report download ======

# ## Report parameters
# ## !!! ADD HERE ClusterngVariance and Reporting area
# ch     <- rv$inputs$data$chain_summary
# lang   <- ch$selectedLanguage %||% "en"
# schema <- tibble::as_tibble(rv$inputs$data$schema_summary)

# strat_name <- paste0(
#   dplyr::coalesce(unname(sampling_strategy_labels[as.character(ch$samplingStrategy %||% "")]), "Unknown"),
#   " (", ch$samplingStrategy, ")"
# )

# stratum_raw   <- ch$stratumAttribute %||% ""
# stratum_label <- if (nzchar(stratum_raw)) {
#   paste0(utils_find_label(schema, stratum_raw, lang), " (", stratum_raw, ")")
# } else "-"

# is_clustered <- nzchar(ch$clusteringEntity %||% "")
# cluster_attr <- if (is_clustered) {
#   keys   <- ch$clusteringEntityKeys %||% character(0)
#   labels <- utils_find_label(schema, keys, lang)
#   paste(paste0(labels, " (", keys, ")"), collapse = ", ")
# } else "-"

# entity_label <- dplyr::coalesce(
#   names(rv$insights$entities_named)[which(unname(rv$insights$entities_named) == rv$analysis$entity)[1]],
#   rv$analysis$entity
# )

# report_dims <- rv$analysis$dim_meta |>
#   dplyr::filter(.data$report_type == "dimension", .data$name %in% rv$analysis$dims)
# base_dims <- report_dims |> dplyr::filter(.data$dimension_baseunit) |> dplyr::pull("label")
# sub_dims  <- report_dims |> dplyr::filter(!.data$dimension_baseunit) |> dplyr::pull("label")

# ## Filters that exclude at least one class
# dim_labels <- purrr::set_names(rv$analysis$dim_meta$label, rv$analysis$dim_meta$name)
# active_filters <- filter_vals |>
#   purrr::imap(\(selected_vals, d) {
#     all_vals <- sort(unique(rv$analysis$result$MEANS[[d]]))
#     if (length(selected_vals) == 0 || setequal(selected_vals, all_vals)) return(NULL)
#     paste0(unname(dim_labels[d]), ": ", paste(selected_vals, collapse = ", "))
#   }) |>
#   purrr::compact()

# summary_params <- list(
#   survey_label             = ch$surveyLabel %||% "Survey",
#   report_author            = paste(
#     "Prepared with ArenaLytics",
#     "https://openforis-shiny.shinyapps.io/arenalytics/",
#     format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
#     sep = " | "
#   ),
#   survey_code              = paste0(ch$surveyLabel %||% ch$surveyName, " (", ch$surveyName, ")"),
#   cycle_number             = as.character(ch$selectedCycle %||% "-"),
#   sampling_strategy        = strat_name,
#   stratification_attribute = stratum_label,
#   clustering               = if (is_clustered) "Yes" else "No",
#   clustering_attribute     = cluster_attr,
#   nonresponse_correction   = if (isTRUE(ch$nonResponseBiasCorrection)) "Yes" else "No",
#   analysis_entity          = entity_label,
#   analysis_type            = if (is_area) "Area" else "Other measures",
#   base_unit_dimensions     = if (length(base_dims) > 0) paste(base_dims, collapse = ", ") else "None",
#   sub_unit_dimensions      = if (length(sub_dims) > 0) paste(sub_dims, collapse = ", ") else "None",
#   measure_label            = sel_measure$label,
#   measure_unit             = dplyr::coalesce(sel_measure$unit, ""),
#   confidence_level         = as.character(input$analysis_p_value %||% "0.95"),
#   filters_applied          = if (length(active_filters) > 0) paste(active_filters, collapse = "; ") else "None",
#   table_title              = if (identical(input$analysis_table_source, "TOTALS")) "Totals" else "Means (per ha)",
#   has_means_plot           = !is_area
# )
# summary_params

# ## Render report to out_dir
# if (save_outputs) {
#   report_dir <- tempfile(pattern = "arenalytics-report-")
#   dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

#   means_plot_file  <- file.path(report_dir, "means-plot.png")
#   totals_plot_file <- file.path(report_dir, "totals-plot.png")
#   table_file       <- file.path(report_dir, "analysis-table.csv")
#   qmd_file         <- file.path(report_dir, "analysis-report.qmd")

#   file.copy(system.file("quarto", "analysis-report.qmd", package = "arenalytics"), qmd_file, overwrite = TRUE)

#   if (!is_area) {
#     ggplot2::ggsave(means_plot_file, plot = analysis_plots$light$MEANS, width = 10, height = 6, dpi = 300)
#   }
#   ggplot2::ggsave(totals_plot_file, plot = analysis_plots$light$TOTALS, width = 10, height = 6, dpi = 300)
#   utils::write.csv(analysis_table, table_file, row.names = FALSE)

#   rendered_file <- file.path(
#     report_dir,
#     paste0("analysis-report.", if (identical(input$analysis_report_format, "docx")) "docx" else "html")
#   )

#   quarto::quarto_render(
#     input = qmd_file,
#     output_format = input$analysis_report_format,
#     execute_params = c(summary_params, list(
#       table_csv   = table_file,
#       means_plot  = if (is_area) "" else means_plot_file,
#       totals_plot = totals_plot_file
#     )),
#     output_file = basename(rendered_file),
#     quiet = FALSE
#   )

#   file.copy(
#     rendered_file,
#     file.path(out_dir, paste0(download_prefix, "report.", tools::file_ext(rendered_file))),
#     overwrite = TRUE
#   )
#   out_dir
# }
