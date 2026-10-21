#' Tool module server function
#'
#' @importFrom rlang .data :=
#'
#' @noRd
mod_tool_server <- function(id, rv) {

  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    ## !!! FOR TESTING: see tests/check-toolserver.R



    ##
    ## ACCORDION ######
    ##

    ## + ACC1: Load data ======

    ## ++ Check data file on load ------

    ## (1) check data files list, (2) update message and (3) activate read button
    observeEvent(input$load_zip, {

      rv$inputs$pathzip <- input$load_zip$datapath
      rv$inputs$checkzip <- fct_checkzip(.path = rv$inputs$pathzip)

      shinyjs::hide("msg_no_file")
      shinyjs::toggle("msg_file_ok",    condition = rv$inputs$checkzip$all_ok)
      shinyjs::toggle("msg_file_error", condition = !rv$inputs$checkzip$all_ok)
      shinyjs::toggleState("btn_read_data", condition = rv$inputs$checkzip$all_ok)

    })

    output$file_error_detail1 <- output$file_error_detail2 <- renderPrint({
      req(rv$inputs$checkzip)
      if(!rv$inputs$checkzip$all_ok | !rv$inputs$checkzip$has_taxonomies) {
        cat("Missing files:\n", paste(rv$inputs$checkzip$missing, collapse = ", "))
      }
    })

    ## ++ Read data on button read ------

    ## Show progress in panel insights
    observeEvent(input$btn_read_data, {

      session$sendCustomMessage("activate-tab", list(id = ns("tool_tabs"), value = "tab_insights"))
      session$sendCustomMessage("scroll_top", list())

      ## Disable Read data button (second click triggers error message)
      shinyjs::disable("btn_read_data")

      ## Hide/Show panels
      shinyjs::hide("panel_insight_msg")
      shinyjs::show("panel_insight_progress")
      shinyjs::hide("panel_insights")

      ## Reset progress
      rv$inputs$data <- NULL
      rv$inputs$data_ok <- FALSE
      shinyjs::html("readdata_console", "")  # clear on restart
      shinyWidgets::updateProgressBar(
        session = session,
        id = "readdata_progress",
        value = 0
      )
      shinyjs::disable("btn_data_insights")

      Sys.sleep(0.4)

      ## Read data and update progress
      ## All messages from fct_readzip() — including per-file success/error lines
      ## and the final summary — are captured here and appended to the console div.
      tmp_out <- withCallingHandlers(
        {
          ## +++
          fct_readzip(
            .path = rv$inputs$pathzip, .pb_ss = session, .pb_id = "readdata_progress"
          )
          ## +++
        },
        message = function(m) {
          shinyjs::html(id = "readdata_console", html = paste0(m$message, '<br>'), add = TRUE)
          invokeRestart("muffleMessage")
        }
      )

      ## Assign the function output to rv$inputs
      purrr::iwalk(tmp_out, \(value, name) rv$inputs[[name]] <- value)

      ## Enable the insight button only when data loaded AND no read errors.
      ## Any error lines are already visible in the console div above.
      rv$inputs$data_ok <- !is.null(rv$inputs$data) && length(rv$inputs$errors) == 0

      shinyjs::toggleState("btn_data_insights", condition = rv$inputs$data_ok)

    })

    ## ++ Show insights on button show insight (insight panel) ------

    observeEvent(input$btn_data_insights, {
      req(rv$inputs$data)

      ## Hide progress and show insights
      shinyjs::hide("panel_insight_progress")
      shinyjs::show("panel_insights")
    })

    ## + ACC2: Entities ======

    observe({
      req(rv$inputs$data)

      if (length(names(rv$inputs$data)) > 0) {
        ## Convention entities = 'tree' etc., entities_labs = 'Tree'
        rv$insights$entities  <- names(rv$inputs$data) |>
          stringr::str_subset(rv$inputs$checkzip$entity_prefix) |>
          stringr::str_remove(rv$inputs$checkzip$entity_prefix)

        entity_lang <- rv$inputs$data$schema_summary |>
          dplyr::as_tibble() |>
          dplyr::filter(.data$type == "entity") |>
          dplyr::select("name", dplyr::starts_with("label"))

        rv$insights$entities_labs  <- utils_find_label(
          .df = entity_lang,
          .name = rv$insights$entities,
          .lang = rv$inputs$data$chain_summary$selectedLanguage
        )
        rv$insights$entities_named <- purrr::set_names(rv$insights$entities, rv$insights$entities_labs)

      } else {
        rv$insights$entities_named <- NULL
      }
    })

    ## ++ Entity selector UI ------

    output$analysis_entity <- renderUI({
      req(rv$insights$entities_named)
      selectInput(
        inputId  = ns("analysis_sel_entity"),
        label    = strong("Entity"),
        choices  = rv$insights$entities_named,
        multiple = FALSE
      )
    })

    ## ++ Prepare dimensions for selected entity ------

    ## Recomputed each time entity changes
    observeEvent(input$analysis_sel_entity, {
      req(rv$inputs$data)

      rv$analysis$dim_meta <- rv$inputs$var_meta[[input$analysis_sel_entity]]

      ## !!! TO INSPECT FURTHER !!!
      strat_row <- rv$analysis$dim_meta |> dplyr::filter(.data$stratum)
      rv$analysis$strat_label <- if (nrow(strat_row) > 0) strat_row$label[1] else NULL

      shinyjs::disable("btn_run_analysis")
    })

    ## ++ Area vs measures UI ------

    observeEvent(input$analysis_mode, {
      shinyjs::toggle("analysis_entity", condition = !identical(input$analysis_mode, "area"))
      shinyjs::disable("btn_run_analysis")
    })

    ## ++ Dimension checkbox UI (base-unit then sub-unit) ------

    output$analysis_dims <- renderUI({
      req(rv$analysis$dim_meta, input$analysis_mode)

      bu_choices  <- utils_make_grp(.rv = rv, .is_bu = TRUE)
      sub_choices <- utils_make_grp(.rv = rv, .is_bu = FALSE)

      tagList(
        tags$label(class = "form-label", strong("Base-unit dimensions")),
        shinyWidgets::checkboxGroupButtons(
          inputId    = ns("analysis_bu_dims"),
          status     = "outline-secondary", ## Open Foris green toggles
          label      = NULL,
          choices    = bu_choices,
          individual = TRUE,
          size       = "sm"
        ),
        if (input$analysis_mode != "area" && length(sub_choices) > 0) tagList(
          hr(style = "margin: 0.5rem 0;"),
          tags$label(class = "form-label", strong("Sub-unit dimensions")),
          shinyWidgets::checkboxGroupButtons(
            inputId    = ns("analysis_sub_dims"),
            status     = "outline-secondary", ## Open Foris green toggles
            label      = NULL,
            choices    = sub_choices,
            individual = TRUE,
            size       = "sm"
          )
        )
      )
    })

    ## ++ Enable Analysis button UI ------

    ## Enable run button when at least one dim is selected
    observe({
      rv$analysis$dims_sel <- if (identical(input$analysis_mode, "area")) {
        input$analysis_bu_dims
      } else {
        c(input$analysis_bu_dims, input$analysis_sub_dims)
      }
      shinyjs::toggleState("btn_run_analysis", condition = isTruthy(rv$analysis$dims_sel))
    })

    ## ++ Too-many-dims warning UI ------

    output$analysis_too_many_dims <- renderUI({
      req(length(rv$analysis$dims_sel) > 4)
      div(
        class = "text-warning",
        style = "font-size: 0.85em; font-style: italic; margin-top: 0.25rem;",
        bsicons::bs_icon("exclamation-triangle"),
        " More than 4 dimensions selected, computation may be slow."
      )
    })

    ## ++ Stratum note UI ------

    output$analysis_strat_text <- renderUI({
      req(!identical(input$analysis_mode, "area"))
      req(rv$analysis$strat_label)
      div(
        class = "text-info",
        style = "font-size: 0.85em; font-style: italic; margin-top: 0.25rem;",
        bsicons::bs_icon("info-circle"),
        paste0(" '", rv$analysis$strat_label, "' is used for stratification.")
      )
    })

    ## + ACC3: Run analysis =======

    observeEvent(input$btn_run_analysis, {
      req(rv$inputs$data, input$analysis_sel_entity, rv$analysis$dims_sel)

      is_area <- identical(input$analysis_mode, "area")

      ## Move to top of Analysis panel
      session$sendCustomMessage("activate-tab", list(id = ns("tool_tabs"), value = "tab_analysis"))
      session$sendCustomMessage("scroll_top", list())

      ## Measures info for plot selector
      rv$analysis$measures_meta <- if (is_area) {
        tibble::tibble(name = "area", label = "Area")
      } else {
        rv$inputs$var_meta[[input$analysis_sel_entity]] |>
          dplyr::filter(.data$report_type == "measure")
      }

      shinyjs::disable("btn_run_analysis")
      shinyjs::hide("analysis_no_result")
      shinyjs::hide("analysis_results")
      shinyjs::show("analysis_progress")
      shinyjs::html("analysis_console", "")
      shinyjs::disable("btn_analysis_results")
      shinyWidgets::updateProgressBar(
        session = session,
        id = "analysis_progress_bar",
        value = 0
      )

      ## ++ Compute results ------
      ## Area mode: sum of expansion factors per base-unit dimensions
      ## Other measures: survey estimation with fct_arenalyse()
      result <- tryCatch(
        withCallingHandlers(
          {
            if (is_area) {
              message(sprintf("[%s] Preparing area summary.", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
              shinyWidgets::updateProgressBar(session = session, id = "analysis_progress_bar", value = 30)

              base_uuid <- paste0(rv$inputs$data$chain_summary$baseUnit, "_uuid")

              area_df <- rv$inputs$data[[paste0(rv$inputs$checkzip$entity_prefix, input$analysis_sel_entity)]] |>
                tibble::as_tibble() |>
                dplyr::rename(dplyr::any_of(c(mau_baseunit_total = "OLAP_baseunit_total"))) |>
                dplyr::filter(.data$mau_baseunit_total == TRUE, .data$weight > 0, .data$exp_factor_ != 0) |>
                dplyr::mutate(dplyr::across(dplyr::all_of(rv$analysis$dims_sel), as.character)) |>
                dplyr::select(dplyr::all_of(c(base_uuid, rv$analysis$dims_sel)), "exp_factor_") |>
                dplyr::distinct() |>
                dplyr::summarise(area = sum(.data$exp_factor_), .by = dplyr::all_of(rv$analysis$dims_sel))

              message(sprintf("[%s] Area summary completed.", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
              shinyWidgets::updateProgressBar(session = session, id = "analysis_progress_bar", value = 100)

              list(MEANS = area_df, TOTALS = area_df)

            } else {

              ## +++
              fct_arenalyse(
                .zip    = rv$inputs,
                .entity = input$analysis_sel_entity,
                .dim    = rv$analysis$dims_sel,
                .pvalue = as.numeric(input$analysis_p_value),
                .cm     = input$analysis_compute_mode,
                .lonely = input$analysis_lonely_psu,
                .pb_ss  = session,
                .pb_id  = "analysis_progress_bar"
              )
              ## +++

            }
          },
          message = function(m) {
            shinyjs::html(id = "analysis_console", html = paste0(m$message, '<br>'), add = TRUE)
            invokeRestart("muffleMessage")
          }
        ),
        error = function(e) {
          shinyjs::disable("btn_analysis_results")
          shinyWidgets::sendSweetAlert(
            session = session, title = "Analysis error",
            text = e$message, type = "error"
          )
          NULL
        }
      )

      shinyjs::enable("btn_run_analysis")
      req(result)

      ## ++ Polish results ------
      ## Replace dimension codes with labels: scientific names for taxonomies,
      ## category labels otherwise. Then drop technical columns and move counts last.
      label_col <- paste0("label_", rv$inputs$data$chain_summary$selectedLanguage)
      dim_meta  <- rv$analysis$dim_meta |> dplyr::filter(.data$report_type == "dimension")
      cats      <- rv$inputs$data$categories
      taxos     <- rv$inputs$data$taxonomies %||% list()
      cols_drop <- if (is_area) character(0) else c("area", "JOIN_COL")

      rv$analysis$result <- purrr::map(result, \(df) {
        intersect(dim_meta$name, names(df)) |>
          purrr::reduce(\(acc, col) {
            cat_name <- dim_meta |> dplyr::filter(.data$name == col) |> dplyr::pull("categoryName") |> dplyr::first()
            if (is.na(cat_name) || !nzchar(cat_name)) return(acc)

            taxo_tbl <- taxos[[cat_name]]
            cat_tbl  <- cats[[cat_name]]

            is_taxo <- !is.null(taxo_tbl) && "scientific_name" %in% names(taxo_tbl)

            ## Category lookup in category order: by parent codes for hierarchical categories, then code
            lookup <- if (is_taxo) {
              purrr::set_names(as.character(taxo_tbl$scientific_name), as.character(taxo_tbl$code))
            } else if (!is.null(cat_tbl)) {
              lbl_col <- if (label_col %in% names(cat_tbl)) label_col else "label"
              cat_tbl <- cat_tbl |> dplyr::arrange(dplyr::across(dplyr::matches("^level_\\d+_code$")), .data$code)
              ## !!! Replaced code with code_joint, should solve multi-level cats
              purrr::set_names(as.character(cat_tbl[[lbl_col]]), as.character(cat_tbl$code_joint))
            }
            if (is.null(lookup)) return(acc)

            acc <- acc |>
              dplyr::mutate(!!col := dplyr::coalesce(unname(lookup[as.character(.data[[col]])]), as.character(.data[[col]])))
            if (is_taxo) return(acc)

            ## Category labels as factors to keep category order in tables and plots
            acc |>
              dplyr::mutate(!!col := factor(.data[[col]], levels = unique(c(unname(lookup), sort(unique(.data[[col]]))))))
          }, .init = df) |>
          dplyr::select(-dplyr::any_of(cols_drop)) |>
          dplyr::relocate(dplyr::any_of(c("item_count", "base_unit_count", "cluster_count")), .after = dplyr::last_col())
      })

      rv$analysis$dims   <- rv$analysis$dims_sel
      rv$analysis$entity <- input$analysis_sel_entity
      rv$analysis$mode   <- input$analysis_mode

      shinyjs::enable("btn_analysis_results")
    })

    ## ++ Show results ------

    observeEvent(input$btn_analysis_results, {
      req(rv$analysis$result)
      shinyjs::hide("analysis_progress")
      shinyjs::hide("analysis_no_result")
      shinyjs::show("analysis_results")
    })



    ##
    ## Panel insights ######
    ##

    ## + Survey info ======

    output$insight_chain_info <- renderUI({
      req(rv$inputs$data)
      ch     <- rv$inputs$data$chain_summary
      lang   <- ch$selectedLanguage %||% "en"
      schema <- tibble::as_tibble(rv$inputs$data$schema_summary)

      ## Sampling strategy code → human-readable name
      sampling_strategy_labels <- c(
        "1" = "Random Sampling",
        "2" = "Systematic Sampling",
        "3" = "Stratified Random Sampling",
        "4" = "Stratified Systematic Sampling",
        "5" = "Two-phase Sampling"
      )
      strat_name <- dplyr::coalesce(
        unname(sampling_strategy_labels[as.character(ch$samplingStrategy %||% "")]), "Unknown"
      )

      ## Stratification attribute label
      stratum_raw <- ch$stratumAttribute %||% ""
      stratum_label <- if (nzchar(stratum_raw)) {
        paste0(utils_find_label(schema, stratum_raw, lang), " [", stratum_raw, "]")
      } else {
        "-"
      }

      ## Clustering variable labels
      is_clustered <- nzchar(ch$clusteringEntity %||% "")
      cluster_attr <- if (is_clustered) {
        keys   <- ch$clusteringEntityKeys %||% character(0)
        labels <- utils_find_label(schema, keys, lang)
        paste(paste0(labels, " [", keys, "]"), collapse = ", ")
      } else {
        "-"
      }

      survey_name <- paste0(ch$surveyLabel %||% ch$surveyName, " [", ch$surveyName, "]")

      info_rows <- c(
        "Cycle"                        = ch$selectedCycle %||% "-",
        "Sampling strategy"            = strat_name,
        "Stratification attribute"     = stratum_label,
        "Clustering"                   = if (is_clustered) "Yes" else "No",
        "Clustering entity"            = cluster_attr,
        "Non-response bias correction" = if (isTRUE(ch$nonResponseBiasCorrection)) "Yes" else "No"
      )

      tags$div(
        tags$p(
          tags$strong("Survey: "), survey_name, style = "margin: 0 0 0.4rem 0; font-size: 1.5rem;",
        ),
        purrr::imap(info_rows, \(value, label) tags$p(
          style = "margin: 0.15rem 0;",
          tags$strong(paste0(label, ": ")), value
        ))
      )
    })

    ## + Current selection ======

    output$insight_current_selection <- renderUI({
      req(rv$inputs$data)

      if (!isTruthy(input$analysis_sel_entity)) {
        return(tags$p(
          class = "text-muted fst-italic",
          "Choose an entity and dimensions in 'Run analysis' to inspect the current selection."
        ))
      }

      selected_dims <- c(input$analysis_bu_dims, input$analysis_sub_dims)

      ## Resolve dimension codes → labels from dim_meta
      dim_meta <- rv$analysis$dim_meta
      dim_labels <- if (!is.null(dim_meta) && length(selected_dims) > 0) {
        dplyr::coalesce(dim_meta$label[match(selected_dims, dim_meta$name)], selected_dims)
      } else {
        selected_dims
      }
      selection_text <- if (length(dim_labels) == 0) "No dimensions selected." else paste(dim_labels, collapse = ", ")

      ## Resolve entity code → label
      entity_label <- rv$insights$entities_named[rv$insights$entities_named == input$analysis_sel_entity]
      entity_label <- if (length(entity_label) > 0) names(entity_label)[1] else input$analysis_sel_entity

      tags$div(
        if (!identical(input$analysis_mode, "area")) tags$p(
          tags$strong("Entity: "),
          entity_label
        ),
        tags$p(
          tags$strong("Analysis type: "),
          if (identical(input$analysis_mode, "area")) "Area" else "Other measures"
        ),
        tags$p(
          tags$strong("Selected dimensions: "),
          selection_text
        )
      )
    })

    ## + Selected entity data, dims and measures ======

    insight_ctx <- reactive({
      req(rv$inputs$data, input$analysis_sel_entity)

      is_area  <- identical(input$analysis_mode, "area")
      dim_meta <- rv$inputs$var_meta[[input$analysis_sel_entity]]

      list(
        dim_meta     = dim_meta,
        entity_table = rv$inputs$data[[paste0(rv$inputs$checkzip$entity_prefix, input$analysis_sel_entity)]] |>
          tibble::as_tibble(),
        dims = list(
          bu  = input$analysis_bu_dims %||% character(0),
          sub = if (is_area) character(0) else input$analysis_sub_dims %||% character(0)
        ),
        meas_meta = if (is_area) {
          tibble::tibble(name = "area", label = "Area")
        } else {
          dim_meta |> dplyr::filter(.data$report_type == "measure")
        }
      )
    })

    ## + Base-unit and sub-unit dimension classes ======

    ## Outputs: insight_bu_out, insight_sub_out
    purrr::walk(c("bu", "sub"), \(grp) {

      output[[paste0("insight_", grp, "_out")]] <- renderUI({
        ctx  <- insight_ctx()
        sel  <- ctx$dims[[grp]]
        lang <- rv$inputs$data$chain_summary$selectedLanguage %||% "en"

        if (length(sel) == 0) {
          return(tags$p(class = "text-muted fst-italic", style = "font-size: 0.85em;", "No selection."))
        }

        purrr::map(sel, \(v) {
          meta_row   <- ctx$dim_meta |> dplyr::filter(.data$name == v) |> dplyr::slice(1)
          cat_name   <- meta_row$categoryName[[1]]
          values_raw <- ctx$entity_table[[v]]

          ## Unique non-missing classes, with category labels when available
          values <- values_raw |>
            as.character() |>
            stringr::str_subset(".") |>
            unique() |>
            sort()

          cat_tbl <- if (!is.na(cat_name) && nzchar(cat_name)) rv$inputs$data$categories[[cat_name]]

          if (!is.null(cat_tbl)) {
            cat_tbl   <- tibble::as_tibble(cat_tbl)
            label_col <- paste0("label_", lang)
            lbl_col   <- if (label_col %in% names(cat_tbl)) label_col else "label"
            lookup    <- purrr::set_names(as.character(cat_tbl[[lbl_col]]), as.character(cat_tbl$code))
            values    <- dplyr::coalesce(unname(lookup[values]), values)
          }

          tags$div(
            style = "margin-bottom: 0.85rem;",
            tags$div(
              tags$strong(meta_row$label[[1]]),
              if (any(!is.na(values_raw) & values_raw == "")) tags$span(
                " Empty class present",
                class = "badge text-bg-warning",
                style = "margin-left: 0.5rem;"
              ),
              if (any(is.na(values_raw))) tags$span(
                " NA present",
                class = "badge text-bg-danger",
                style = "margin-left: 0.5rem;"
              )
            ),
            if (length(values) > 0) {
              tags$div(
                style = "font-size: 0.85em; margin-top: 0.35rem;",
                paste(values, collapse = ", ")
              )
            } else {
              tags$p(
                class = "text-muted fst-italic",
                style = "font-size: 0.85em; margin-top: 0.35rem;",
                "No non-missing classes."
              )
            }
          )
        }) |>
          tagList()
      })

    })

    ## + Measures ======

    output$insight_meas_out <- renderUI({
      meas_labels <- insight_ctx()$meas_meta$label

      if (length(meas_labels) == 0) {
        return(tags$p(class = "text-muted fst-italic", style = "font-size: 0.85em;", "No measures available."))
      }

      tags$ul(
        style = "font-size: 0.85em; margin-bottom: 0;",
        purrr::map(meas_labels, tags$li)
      )
    })



    ##
    ## Panel analysis ######
    ##

    ## + Layout by analysis mode (area mode has no means) ======

    observeEvent(list(rv$analysis$mode, input$btn_analysis_results), {
      req(rv$analysis$mode)
      is_area <- identical(rv$analysis$mode, "area")

      shinyjs::toggle("analysis_table_source_wrap", condition = !is_area)
      shinyjs::toggle("analysis_means_card", condition = !is_area)

      updateSelectInput(
        session,
        "analysis_table_source",
        choices = if (is_area) c("Totals" = "TOTALS") else c("Means (per ha)" = "MEANS", "Totals" = "TOTALS"),
        selected = if (is_area) "TOTALS" else (input$analysis_table_source %||% "MEANS")
      )
    })

    ## + Plot selectors ======

    ## Updated when a new result arrives
    observeEvent(rv$analysis$result, {
      req(rv$analysis$result, rv$analysis$dim_meta, rv$analysis$measures_meta)

      dim_meta    <- rv$analysis$dim_meta |> dplyr::filter(.data$name %in% rv$analysis$dims)
      dim_choices <- purrr::set_names(dim_meta$name, dim_meta$label)
      meas_choices <- purrr::set_names(rv$analysis$measures_meta$name, rv$analysis$measures_meta$label)

      n_dims <- length(dim_choices)
      optional_choices <- c("-- None --" = "", dim_choices)
      facet_choices <- if (n_dims >= 2) optional_choices else c("-- None --" = "")

      updateSelectInput(session, "analysis_sel_measure", choices = meas_choices, selected = meas_choices[1])
      updateSelectInput(session, "plot_dim", choices = dim_choices, selected = dim_choices[1])
      updateSelectInput(session, "plot_fill", choices = optional_choices, selected = "")
      updateSelectInput(session, "plot_facet", choices = facet_choices, selected = "")

      shinyjs::enable("plot_fill")
      shinyjs::toggleState("plot_facet", condition = n_dims >= 2)
    })

    ## + Selected measure ======

    sel_measure <- reactive({
      req(rv$analysis$measures_meta)
      measure_name <- input$analysis_sel_measure %||% dplyr::first(rv$analysis$measures_meta$name)
      meas_row     <- rv$analysis$measures_meta |> dplyr::filter(.data$name == measure_name)

      list(
        name  = measure_name,
        label = dplyr::first(meas_row$label),
        unit  = if ("unit" %in% names(meas_row)) dplyr::first(meas_row$unit) else NA_character_
      )
    })

    ## + Dimension filters ======

    ## One multi-select per dimension used in the analysis (all dims, regardless
    ## of role). Default = all values selected (no filter applied).
    output$analysis_extra_filters <- renderUI({
      req(rv$analysis$result, rv$analysis$dim_meta)

      filter_inputs <- purrr::map(rv$analysis$dims, \(d) {
        vals <- as.character(sort(unique(rv$analysis$result$MEANS[[d]])))
        shinyWidgets::virtualSelectInput(
          inputId          = ns(paste0("filter_dim__", d)),
          label            = rv$analysis$dim_meta |> dplyr::filter(.data$name == d) |> dplyr::pull("label") |> dplyr::first(),
          choices          = purrr::set_names(vals),
          selected         = vals,          ## all selected by default → no filter
          multiple         = TRUE,
          showValueAsTags  = TRUE,
          search           = TRUE,
          dropboxWrapper   = "body",
          width            = "100%"
        )
      })

      if (length(filter_inputs) == 0) return(NULL)

      div(
        style = "margin-top: 0.75rem;",
        tags$small(class = "text-muted", bsicons::bs_icon("funnel"), " Dimension filters"),
        layout_column_wrap(width = "180px", fill = FALSE, !!!filter_inputs)
      )
    })

    ## Current filter values for all dims, named by dim
    filter_vals <- reactive({
      purrr::map(
        purrr::set_names(rv$analysis$dims %||% character(0)),
        \(d) input[[paste0("filter_dim__", d)]]
      )
    })

    ## + Filtered results ======

    ## MEANS and TOTALS with dimension filters applied
    analysis_filtered <- reactive({
      req(rv$analysis$result)
      filters <- purrr::compact(filter_vals())

      purrr::map(rv$analysis$result, \(df) {
        purrr::reduce(names(filters), \(acc, d) dplyr::filter(acc, .data[[d]] %in% filters[[d]]), .init = df)
      })
    })

    ## + Output table ======

    ## Dims, other columns, selected measure columns then counts, with labels as column names
    analysis_table <- reactive({
      req(rv$analysis$result, rv$analysis$dim_meta, input$analysis_table_source, input$analysis_sel_measure)

      df            <- analysis_filtered()[[input$analysis_table_source]]
      measure       <- sel_measure()
      measure_names <- rv$analysis$measures_meta$name
      dim_names     <- rv$analysis$dims %||% character(0)
      count_cols    <- intersect(c("item_count", "base_unit_count", "cluster_count"), names(df))

      ## !!! Solved nested col names being selected.
      nested_measures <- measure_names |>
        setdiff(measure$name) |>
        purrr::keep(\(m) stringr::str_starts(m, measure$name))

      measure_cols <- names(df) |>
        purrr::keep(\(x) stringr::str_starts(x, measure$name)) |>
        purrr::discard(\(x) length(nested_measures) > 0 && any(stringr::str_starts(x, nested_measures)))

      all_measure_cols <- purrr::map(measure_names, \(m) stringr::str_subset(names(df), paste0("^", m, "($|_)"))) |>
        unlist()
      other_cols <- setdiff(names(df), c(dim_names, count_cols, all_measure_cols))

      ## Column labels, first match wins: dimensions, fixed columns, selected measure
      ## !!! ERROR HERE IF 2 VARS HAVE SAME NAME AND ONE IS EXTENDED !!!
      dim_meta <- rv$analysis$dim_meta |> dplyr::filter(.data$report_type == "dimension")
      col_labels <- c(
        purrr::set_names(dim_meta$label, dim_meta$name),
        area            = "Area",
        item_count      = "Item count",
        base_unit_count = "Base unit count",
        cluster_count   = "Cluster count",
        purrr::set_names(
          paste0(measure$label, c("", " (SE)", " (Lower CI)", " (Upper CI)")),
          paste0(measure$name,  c("", "_se",  "_low",        "_upp"))
        )
      )

      df |>
        dplyr::select(dplyr::all_of(unique(c(dim_names, other_cols, measure_cols, count_cols)))) |>
        purrr::set_names(\(cols) dplyr::coalesce(unname(col_labels[cols]), cols))
    })

    output$analysis_table <- DT::renderDT({
      table_df <- analysis_table()

      numeric_cols <- names(purrr::keep(table_df, is.numeric))
      count_cols   <- stringr::str_subset(numeric_cols, "count$")
      measure_cols <- setdiff(numeric_cols, count_cols)

      table_out <- DT::datatable(
        table_df,
        rownames = FALSE,
        filter = "top",
        options = list(
          scrollX = TRUE,
          pageLength = 10
        )
      )

      if (length(measure_cols) > 0) {
        table_out <- DT::formatRound(table_out, columns = measure_cols, digits = 3, mark = ",")
      }
      if (length(count_cols) > 0) {
        table_out <- DT::formatRound(table_out, columns = count_cols, digits = 0, mark = ",")
      }

      table_out
    })

    ## + Copy table to clipboard (tab separated) ======

    observeEvent(input$analysis_table_copy, {
      table_df <- analysis_table()

      table_rows <- table_df |>
        dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) |>
        tidyr::unite("row", dplyr::everything(), sep = "\t") |>
        dplyr::pull("row")

      txt <- paste(c(paste(names(table_df), collapse = "\t"), table_rows), collapse = "\n")

      shinyjs::runjs(sprintf("navigator.clipboard.writeText(%s);", jsonlite::toJSON(txt, auto_unbox = TRUE)))
    })

    ## + Plot validation ======

    ## A plot is valid when every analysis dim is either used in the plot
    ## (x axis, fill or facet) or filtered down to a single class.
    plot_validation <- reactive({
      req(rv$analysis$dims, input$plot_dim)

      role_dims    <- c(input$plot_dim, input$plot_fill, input$plot_facet) |> stringr::str_subset(".") |> unique()
      filters      <- filter_vals()
      invalid_dims <- setdiff(rv$analysis$dims, role_dims) |>
        purrr::discard(\(d) length(filters[[d]]) == 1)

      if (length(invalid_dims) == 0) {
        list(ok = TRUE, message = "All selected dimensions are accounted for in the figure.")
      } else {
        list(
          ok = FALSE,
          message = paste0(
            "To display the figure, assign or reduce these dimensions to one class: ",
            paste(invalid_dims, collapse = ", "), "."
          )
        )
      }
    })

    output$analysis_plot_guidance <- renderUI({
      req(rv$analysis$result)
      validation <- plot_validation()

      div(
        class = if (validation$ok) "text-success" else "text-warning",
        style = "font-size: 0.9em; font-style: italic;",
        if (validation$ok) bsicons::bs_icon("check-circle") else bsicons::bs_icon("exclamation-triangle"),
        paste0(" ", validation$message)
      )
    })

    ## Toggle download buttons when plot is not renderable
    observe({
      req(rv$analysis$result)
      ok <- isTRUE(plot_validation()$ok)
      shinyjs::toggleState("analysis_plot_means_download",  condition = ok)
      shinyjs::toggleState("analysis_plot_totals_download", condition = ok)
      shinyjs::toggleState("analysis_report_download",      condition = ok)
    })

    ## + Plots ======

    ## Bar plots of MEANS and TOTALS, shared by the panel, PNG downloads and report
    analysis_plots <- reactive({
      req(rv$analysis$result, input$plot_dim, input$analysis_sel_measure)
      validate(need(plot_validation()$ok, plot_validation()$message))

      dim_meta  <- rv$analysis$dim_meta
      measure   <- sel_measure()
      x_dim     <- input$plot_dim
      fill_col  <- input$plot_fill
      facet_col <- input$plot_facet
      use_fill  <- isTruthy(fill_col)  && fill_col  != ""
      use_facet <- isTruthy(facet_col) && facet_col != ""
      wrap      <- isTRUE(input$plot_wrap_labels)
      flip      <- isTRUE(input$plot_flip)
      low_col   <- paste0(measure$name, "_low")
      upp_col   <- paste0(measure$name, "_upp")

      ## Axis and legend labels
      x_label    <- dim_meta |> dplyr::filter(.data$name == x_dim) |> dplyr::pull("label") |> dplyr::first()
      y_label    <- measure$label
      fill_label <- if (use_fill) dim_meta |> dplyr::filter(.data$name == fill_col) |> dplyr::pull("label") |> dplyr::first()

      if (wrap) {
        x_label    <- stringr::str_wrap(x_label, width = 28)
        y_label    <- stringr::str_wrap(y_label, width = 28)
        fill_label <- if (use_fill) stringr::str_wrap(fill_label, width = 24)
      }
      tick_labels <- if (wrap) scales::label_wrap(18) else ggplot2::waiver()

      ## Unit for plot titles
      unit_txt <- if (!is.na(measure$unit) && nzchar(measure$unit)) measure$unit else NULL

      ## Bars: dodged and colored by fill dim, or plain grey
      bar_pos <- if (use_fill) ggplot2::position_dodge(width = 0.9, preserve = "single") else "identity"
      base_aes <- if (use_fill) {
        ggplot2::aes(x = .data[[x_dim]], y = .data[[measure$name]], fill = .data[[fill_col]])
      } else {
        ggplot2::aes(x = .data[[x_dim]], y = .data[[measure$name]])
      }
      geom_col_layer <- if (use_fill) {
        ggplot2::geom_col(position = bar_pos, col = "grey30")
      } else {
        ggplot2::geom_col(position = bar_pos, col = "grey30", fill = "grey70")
      }

      purrr::map(c(MEANS = "MEANS", TOTALS = "TOTALS"), \(src) {
        df <- analysis_filtered()[[src]]

        plot_title <- if (src == "MEANS") {
          if (!is.null(unit_txt)) paste0("Aggregated means (", unit_txt, "/ha)") else "Aggregated means"
        } else {
          if (!is.null(unit_txt)) paste0("Aggregated totals (", unit_txt, ")") else "Aggregated totals"
        }

        p <- ggplot2::ggplot(df, base_aes) +
          geom_col_layer +
          ggplot2::labs(x = x_label, y = y_label, fill = fill_label, title = plot_title) +
          ggplot2::theme_minimal() +
          ggplot2::theme(
            axis.text.x = ggplot2::element_text(size = 12, angle = 45, hjust = 1),
            axis.text.y = ggplot2::element_text(size = 12),
            axis.title.x = ggplot2::element_text(size = 14, margin = ggplot2::margin(t = 10)),
            axis.title.y = ggplot2::element_text(size = 14, margin = ggplot2::margin(r = 10)),
            legend.title = ggplot2::element_text(size = 13),
            legend.text = ggplot2::element_text(size = 11),
            strip.text = ggplot2::element_text(size = 12, face = "bold")
          ) +
          ggplot2::scale_x_discrete(
            labels = tick_labels,
            # Reverse order when flipped so first item appears at top (not bottom)
            limits = if (flip) rev else NULL
          )

        if (use_fill) {
          p <- p + ggplot2::scale_fill_discrete(labels = tick_labels)
        }

        if (isTRUE(input$plot_errbar) && all(c(low_col, upp_col) %in% names(df))) {
          p <- p + ggplot2::geom_errorbar(
            ggplot2::aes(ymin = .data[[low_col]], ymax = .data[[upp_col]]),
            position = bar_pos,
            width    = 0.2,
            col = "black"
          )
        }

        if (use_facet) {
          p <- p + ggplot2::facet_wrap(
            ggplot2::vars(!!rlang::sym(facet_col)),
            labeller = ggplot2::labeller(.default = ggplot2::label_wrap_gen(width = 18))
          )
        }

        if (flip) {
          p <- p + ggplot2::coord_flip()
        }

        if (isTRUE(input$plot_hide_legend)) {
          p <- p + ggplot2::theme(legend.position = "none")
        }

        if (src == "TOTALS") {
          p <- p + ggplot2::scale_y_continuous(labels = scales::comma)
        }

        p
      })
    })

    output$analysis_plot_means  <- renderPlot(analysis_plots()$MEANS)
    output$analysis_plot_totals <- renderPlot(analysis_plots()$TOTALS)

    ## + Download file names ======

    ## File names prefix: AA-<survey-name>-
    download_prefix <- reactive({
      req(rv$inputs$data)
      survey_stub <- (rv$inputs$data$chain_summary$surveyName %||% "survey") |>
        stringr::str_replace_all("[^A-Za-z0-9]+", "-") |>
        stringr::str_remove_all("(^-+|-+$)") |>
        tolower()
      paste0("AA-", survey_stub, "-")
    })

    ## + Table CSV download ======

    output$analysis_table_download <- downloadHandler(
      filename = function() paste0(download_prefix(), "full-table.csv"),
      content = function(file) {
        utils::write.csv(analysis_filtered()[[input$analysis_table_source %||% "MEANS"]], file, row.names = FALSE)
      }
    )

    ## + Plot PNG downloads ======

    output$analysis_plot_means_download <- downloadHandler(
      filename = function() paste0(download_prefix(), "fig-mean.png"),
      content = function(file) {
        ggplot2::ggsave(filename = file, plot = analysis_plots()$MEANS, width = 10, height = 6, dpi = 300)
      }
    )

    output$analysis_plot_totals_download <- downloadHandler(
      filename = function() paste0(download_prefix(), "fig-total.png"),
      content = function(file) {
        ggplot2::ggsave(filename = file, plot = analysis_plots()$TOTALS, width = 10, height = 6, dpi = 300)
      }
    )

    ## + Report download ======

    ## reactiveVal drives button enabled/disabled state — changing it from
    ## on.exit() triggers a reactive flush so the WebSocket message is sent.
    report_downloading <- reactiveVal(FALSE)
    observeEvent(report_downloading(), {
      shinyjs::toggleState("analysis_report_download", condition = !report_downloading())
    }, ignoreInit = TRUE)

    output$analysis_report_download <- downloadHandler(
      filename = function() {
        req(rv$inputs$data, input$analysis_report_format)
        ext <- if (identical(input$analysis_report_format, "docx")) "docx" else "html"
        paste0(download_prefix(), "report.", ext)
      },
      contentType = "application/octet-stream",
      content = function(file) {
        req(rv$analysis$result, rv$inputs$data, input$analysis_report_format)

        report_downloading(TRUE)
        on.exit(report_downloading(FALSE), add = TRUE)

        is_area <- identical(rv$analysis$mode, "area")

        ## Prepare report folder and template
        report_dir <- tempfile(pattern = "arenalytics-report-")
        dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

        means_plot_file  <- file.path(report_dir, "means-plot.png")
        totals_plot_file <- file.path(report_dir, "totals-plot.png")
        table_file       <- file.path(report_dir, "analysis-table.csv")
        qmd_template     <- system.file("quarto", "analysis-report.qmd", package = "arenalytics")
        qmd_file         <- file.path(report_dir, "analysis-report.qmd")

        if (!nzchar(qmd_template)) {
          stop("Report template not found.", call. = FALSE)
        }

        ok_copy <- file.copy(qmd_template, qmd_file, overwrite = TRUE)
        if (!isTRUE(ok_copy)) {
          stop("Could not prepare the report template.", call. = FALSE)
        }

        ## Save plots and table
        if (!is_area) {
          ggplot2::ggsave(means_plot_file, plot = analysis_plots()$MEANS, width = 10, height = 6, dpi = 300)
        }
        ggplot2::ggsave(totals_plot_file, plot = analysis_plots()$TOTALS, width = 10, height = 6, dpi = 300)
        utils::write.csv(analysis_table(), table_file, row.names = FALSE)

        ## Report parameters
        ## !!! ADD HERE ClusterngVariance and Reporting area
        ch     <- rv$inputs$data$chain_summary
        lang   <- ch$selectedLanguage %||% "en"
        schema <- tibble::as_tibble(rv$inputs$data$schema_summary)

        sampling_strategy_labels <- c(
          "1" = "Random Sampling",
          "2" = "Systematic Sampling",
          "3" = "Stratified Random Sampling",
          "4" = "Stratified Systematic Sampling",
          "5" = "Two-phase Sampling"
        )
        strat_name <- paste0(
          dplyr::coalesce(unname(sampling_strategy_labels[as.character(ch$samplingStrategy %||% "")]), "Unknown"),
          " (", ch$samplingStrategy, ")"
        )

        stratum_raw   <- ch$stratumAttribute %||% ""
        stratum_label <- if (nzchar(stratum_raw)) {
          paste0(utils_find_label(schema, stratum_raw, lang), " (", stratum_raw, ")")
        } else "-"

        is_clustered <- nzchar(ch$clusteringEntity %||% "")
        cluster_attr <- if (is_clustered) {
          keys   <- ch$clusteringEntityKeys %||% character(0)
          labels <- utils_find_label(schema, keys, lang)
          paste(paste0(labels, " (", keys, ")"), collapse = ", ")
        } else "-"

        entity_label <- dplyr::coalesce(
          names(rv$insights$entities_named)[which(unname(rv$insights$entities_named) == rv$analysis$entity)[1]],
          rv$analysis$entity
        )

        report_dims <- rv$analysis$dim_meta |>
          dplyr::filter(.data$report_type == "dimension", .data$name %in% rv$analysis$dims)
        base_dims <- report_dims |> dplyr::filter(.data$dimension_baseunit) |> dplyr::pull("label")
        sub_dims  <- report_dims |> dplyr::filter(!.data$dimension_baseunit) |> dplyr::pull("label")

        ## Filters that exclude at least one class
        dim_labels <- purrr::set_names(rv$analysis$dim_meta$label, rv$analysis$dim_meta$name)
        active_filters <- filter_vals() |>
          purrr::imap(\(selected_vals, d) {
            all_vals <- sort(unique(rv$analysis$result$MEANS[[d]]))
            if (length(selected_vals) == 0 || setequal(selected_vals, all_vals)) return(NULL)
            paste0(unname(dim_labels[d]), ": ", paste(selected_vals, collapse = ", "))
          }) |>
          purrr::compact()

        summary_params <- list(
          survey_label             = ch$surveyLabel %||% "Survey",
          report_author            = paste(
            "Prepared with Arena Analytics",
            "https://openforis-shiny.shinyapps.io/arenalytics/",
            format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
            sep = " | "
          ),
          survey_code              = paste0(ch$surveyLabel %||% ch$surveyName, " (", ch$surveyName, ")"),
          cycle_number             = as.character(ch$selectedCycle %||% "-"),
          sampling_strategy        = strat_name,
          stratification_attribute = stratum_label,
          clustering               = if (is_clustered) "Yes" else "No",
          clustering_attribute     = cluster_attr,
          nonresponse_correction   = if (isTRUE(ch$nonResponseBiasCorrection)) "Yes" else "No",
          analysis_entity          = entity_label,
          analysis_type            = if (is_area) "Area" else "Other measures",
          base_unit_dimensions     = if (length(base_dims) > 0) paste(base_dims, collapse = ", ") else "None",
          sub_unit_dimensions      = if (length(sub_dims) > 0) paste(sub_dims, collapse = ", ") else "None",
          measure_label            = sel_measure()$label,
          measure_unit             = dplyr::coalesce(sel_measure()$unit, ""),
          confidence_level         = as.character(input$analysis_p_value %||% "0.95"),
          filters_applied          = if (length(active_filters) > 0) paste(active_filters, collapse = "; ") else "None",
          table_title              = if (identical(input$analysis_table_source, "TOTALS")) "Totals" else "Means (per ha)",
          has_means_plot           = !is_area
        )

        ## Render and copy to download target
        rendered_file <- file.path(
          report_dir,
          paste0("analysis-report.", if (identical(input$analysis_report_format, "docx")) "docx" else "html")
        )

        quarto::quarto_render(
          input = qmd_file,
          output_format = input$analysis_report_format,
          execute_params = c(summary_params, list(
            table_csv   = table_file,
            means_plot  = if (is_area) "" else means_plot_file,
            totals_plot = totals_plot_file
          )),
          output_file = basename(rendered_file),
          quiet = FALSE
        )

        if (!file.exists(rendered_file)) {
          stop("Report generation failed.", call. = FALSE)
        }

        ok_out <- file.copy(rendered_file, file, overwrite = TRUE)
        if (!isTRUE(ok_out)) {
          stop("Could not copy the rendered report to the download target.", call. = FALSE)
        }
      }
    )

    ## + Block report double-clicks via JS ======

    ## shinyjs::disable() inside content() is too late — the WebSocket message
    ## may not reach the browser until after the HTTP download response is sent.
    ## This JS handler intercepts the click before the browser follows the href.
    observe({
      shinyjs::runjs(sprintf(
        "$(document).on('click', '#%s', function(e) {
          if ($(this).hasClass('disabled')) { e.preventDefault(); return false; }
          $(this).addClass('disabled');
        });",
        ns("analysis_report_download")
      ))
    })

  })

}
