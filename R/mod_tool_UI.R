#' Tool module UI function
#'
#' @noRd
mod_tool_UI <- function(id, i18n, .tr){

  ## From https://shiny.rstudio.com/articles/modules.html
  # `NS(id)` returns a namespace function, which was save as `ns` and will
  # invoke later.
  ns <- NS(id)


  ##
  ## UI Elements ######
  ##

  ## 3 parts sidebar: Load data, Get insights, Get analysis results
  ## 2 panels: Insights and Analysis


  ## + Sidebar ======

  ## . + Acc1: Load data ------
  ac1 <- accordion_panel(
    title = i18n$t(.tr$ac1_title),
    icon = bsicons::bs_icon("1-circle"),
    value = ns("ac_load"),

    ## Input ZIP file
    div(
      p(i18n$t(.tr$ac1_p1)),
      p(i18n$t(.tr$ac1_p2)),
      fileInput(
        inputId = ns("load_zip"),
        accept = ".zip",
        #buttonLabel = i18n$t(.tr$ac1_input1),
        #placeholder = i18n$t(.tr$ac1_input2),
        label = NULL
      ) |>
        ## FAO primary button for "Browse..." (fileInput() has no button class argument)
        htmltools::tagQuery() |>
        (\(x) x$find(".btn-file")$removeClass("btn-default")$addClass("btn-primary")$allTags())(),
      ## TEST alternative shinyFiles
      ## !!! Package old and not maintained
      # br(),
      # p(
      #   "The dashboard requires a ZIP file that is produced by running the processing
      #   chain from your OF Arena survey in Rstudio (local or online). Once this file
      #   is produced, extract the data and point to its location here, so that the app
      #   can automatically find the data and structure files:"
      # ),
      #
      # shinyFiles::shinyDirButton(
      #   id = ns('path_to_folder'),
      #   label = 'Select a folder',
      #   title = 'Please select a folder',
      #   FALSE
      # )
    ),

    ## MESSAGES
    div(
      id = ns("msg_no_file"),
      i18n$t(.tr$ac1_msg_nodata),
      class = "text-warning",
      style = "font-style: italic;"
    ),
    shinyjs::hidden(div(
      id = ns("msg_file_ok"),
      i18n$t(.tr$ac1_msg_ok),
      verbatimTextOutput(ns("file_error_detail1")),
      class = "text-success",
      style = "font-style: italic;"
    )),
    shinyjs::hidden(div(
      id = ns("msg_file_error"),
      i18n$t(.tr$ac1_msg_err),
      verbatimTextOutput(ns("file_error_detail2")),
      class = "text-danger",
      style = "font-style: italic;"
    )),

    ## ACTION BUTTON
    div(
      shinyjs::disabled(
        actionButton(
          inputId = ns("btn_read_data"),
          label = i18n$t(.tr$ac1_btn),
          class = "btn-primary"
        )
      ),
      style = "margin-top: 1rem;"
    )

  )


  ## $$$
  ## . + Acc2: Insights — REMOVED (entity/variable selection moved into Insights panel)
  ## ac2 <-  accordion_panel(
  ##   title = "Get insights",
  ##   icon = bsicons::bs_icon("2-circle"),
  ##   value = ns("ac2"),
  ##   div(
  ##     id = ns("msg_tmp"),
  ##     p("Under construction"),
  ##     class = "text-warning",
  ##     style = "font-style: italic;"
  ##   ),
  ##   div(
  ##     id = ns("insight_filters"),
  ##     uiOutput(outputId = ns("insight_entity")),
  ##     uiOutput(outputId = ns("insight_vars"))
  ##   )
  ## )
  ## $$$

  ## . + Acc2: Select inputs (analysis type, entity, dimensions) -------------
  ## Segmented switches (status "segment") and dimension chips (status "chip"),
  ## styled in assets/style.css
  ac2 <- accordion_panel(
    title = "Select inputs",
    icon = bsicons::bs_icon("2-circle"),
    value = ns("ac_inputs"),

    ## Area or other measures
    div(
      class = "seg-control",
      shinyWidgets::radioGroupButtons(
        inputId   = ns("analysis_mode"),
        status    = "segment",
        label     = strong("Analysis type"),
        choices   = c("Area" = "area", "Other measures" = "other"),
        selected  = "other",
        size      = "sm",
        justified = TRUE
      )
    ),

    ## Entity selector (populated after data loads)
    uiOutput(ns("analysis_entity")),

    ## Grouped dimension selector (populated after entity is chosen)
    uiOutput(ns("analysis_dims")),

    ## Stratum auto-include note (only when sampling design requires it)
    uiOutput(ns("analysis_strat_text")),

    ## Warning when more than 4 dimensions are selected
    uiOutput(ns("analysis_too_many_dims"))
  )

  ## . + Acc3: Configure analysis (survey options) and run -------------------
  ac3 <- accordion_panel(
    title = "Configure analysis",
    icon = bsicons::bs_icon("3-circle"),
    value = ns("ac_config"),

    ## Lonely-PSU strategy
    div(
      class = "seg-control",
      shinyWidgets::radioGroupButtons(
        inputId   = ns("analysis_lonely_psu"),
        status    = "segment",
        label     = strong("Lonely PSU handling"),
        choices   = c("Adjust" = "adjust", "Remove" = "remove"),
        selected  = "adjust",
        size      = "sm",
        justified = TRUE
      )
    ),
    ## Note for the selected option
    purrr::map2(c("adjust", "remove"), list(.tr$cfg_psu_adjust, .tr$cfg_psu_remove), \(value, txt) {
      conditionalPanel(
        condition = sprintf("input.analysis_lonely_psu == '%s'", value),
        ns = ns,
        ## inner div: the sidebar renders conditional panels with display: contents
        div(
          class = "text-info",
          style = "font-size: 0.85em; font-style: italic; margin-top: 0.25rem; margin-bottom: 1rem;",
          bsicons::bs_icon("info-circle"), " ", i18n$t(txt)
        )
      )
    }),

    ## Computation mode
    div(
      class = "seg-control",
      shinyWidgets::radioGroupButtons(
        inputId   = ns("analysis_compute_mode"),
        status    = "segment",
        label     = strong("Computation mode"),
        choices   = c("Fast" = "fast", "Safe" = "safe"),
        selected  = "fast",
        size      = "sm",
        justified = TRUE
      )
    ),
    ## Note for the selected option
    purrr::map2(c("fast", "safe"), list(.tr$cfg_cm_fast, .tr$cfg_cm_safe), \(value, txt) {
      conditionalPanel(
        condition = sprintf("input.analysis_compute_mode == '%s'", value),
        ns = ns,
        ## inner div: the sidebar renders conditional panels with display: contents
        div(
          class = "text-info",
          style = "font-size: 0.85em; font-style: italic; margin-top: 0.25rem; margin-bottom: 1rem;",
          bsicons::bs_icon("info-circle"), " ", i18n$t(txt)
        )
      )
    }),

    ## Confidence level, values as numbers in text for fct_arenalyse(.pvalue)
    div(
      class = "seg-control",
      shinyWidgets::radioGroupButtons(
        inputId   = ns("analysis_p_value"),
        status    = "segment",
        label     = strong("Confidence level"),
        choices   = c("99%" = "0.99", "95%" = "0.95", "90%" = "0.90", "80%" = "0.80", "68%" = "0.68"),
        selected  = "0.95",
        size      = "sm",
        justified = TRUE
      )
    ),

    ## Run button
    div(
      style = "margin-top: 1rem;",
      shinyjs::disabled(
        actionButton(
          inputId = ns("btn_run_analysis"),
          label   = "Run analysis",
          icon    = icon("play"),
          class   = "btn-primary btn-sm"
        )
      )
    )
  )

  ## + Panels UI ======

  ## . + Insights elements ------
  ## . . + Initial message ------
  insight_msg <- div(
    id = ns("panel_insight_msg"),
    bsicons::bs_icon("arrow-left"), " Start with uploading your MAU zipfile in the sidebar.",
    class = "text-warning",
    style = "font-style: italic;"
  )

  ## . . + Read progress ------
  insight_progress <- shinyjs::hidden(div(
    id = ns("panel_insight_progress"),
    h3("Reading Data"),
    shinyWidgets::progressBar(
      id = ns("readdata_progress"),
      value = 0,
      title = "Reading data",
      display_pct = TRUE
    ),
    br(),
    div(
      id = ns("readdata_console"),
      style =
        "height: 300px; overflow-y: auto; background-color:var(--bs-tertiary-bg); font-family:var(--bs-font-monospace); font-size: small;"
    ),
    br(),
    shinyjs::disabled(
      actionButton(inputId = ns("btn_data_insights"), label = "Show data insights", class = "btn-primary")
    )
  ))

  ## . . + Data insights -----
  insight_p_title <- tagList(
    #tags$h5(textOutput(ns("insight_title"), inline = TRUE)),
    hr(),
    uiOutput(ns("insight_chain_info"))
  )

  ## $$$

  ## Row 1: Base-unit dimensions
  insight_row_bu <- card(
    min_height = "200px",
    card_header(bsicons::bs_icon("diagram-3"), " Base-unit dimensions"),
    uiOutput(ns("insight_bu_out"))
  )

  ## Row 2: Sub-unit dimensions
  insight_row_sub <- card(
    min_height = "200px",
    card_header(bsicons::bs_icon("diagram-2"), " Sub-unit dimensions"),
    uiOutput(ns("insight_sub_out"))
  )

  ## ++ ##
  ## Row 3: Measures
  insight_row_meas <- card(
    min_height = "160px",
    card_header(bsicons::bs_icon("bar-chart"), " Measures"),
    uiOutput(ns("insight_meas_out"))
  )
  ## ++ ##

  ## $$$


  ## . + Panel: analysis ------
  ## Statistical analysis


  ##
  ## Layout UI elements with tagList() function ################################
  ##

  tagList(

    #h2(i18n$t("TOOL")),

    br(),

    navset_card_tab(
      id = ns("tool_tabs"),

      ## + Sidebar =====
      sidebar = sidebar(
        width = "300px",
        accordion(
          open = TRUE,
          multiple = TRUE,
          ## $$$
          ac1, ac2, ac3
          ## $$$
        )
      ),

      ## Spacer to right align menu items
      nav_spacer(),

      ## + Panel insights ===========
      nav_panel(
        title = i18n$t("Insights"),
        value = "tab_insights",
        icon = icon("circle-check"),
        insight_msg,
        insight_progress,
        br(),
        shinyjs::hidden(div(
          id = ns("panel_insights"),
          tags$h3("Data insights"),
          insight_p_title,
          hr(),
          uiOutput(ns("insight_current_selection")),
          hr(),
          insight_row_bu,
          insight_row_sub,
          insight_row_meas
        ))
      ),

      ## + panel Analysis ======================================================

      nav_panel(
        title = i18n$t("Analysis"),
        value = "tab_analysis",
        icon = icon("chart-simple"),

        ## $$$

        ## ++ ##
        ## No-results message (visible until first analysis is run)
        div(
          id    = ns("analysis_no_result"),
          bsicons::bs_icon("arrow-left"),
          " Configure and run an analysis in the sidebar.",
          class = "text-warning",
          style = "font-style: italic;"
        ),

        ## Analysis progress - shown while fct_arenalyse() is running
        shinyjs::hidden(div(
          id = ns("analysis_progress"),
          h3("Running analysis"),
          shinyWidgets::progressBar(
            id = ns("analysis_progress_bar"),
            value = 0,
            title = "Running analysis",
            display_pct = TRUE
          ),
          br(),
          div(
            id = ns("analysis_console"),
            style =
              "height: 300px; overflow-y: auto; background-color:var(--bs-tertiary-bg); font-family:var(--bs-font-monospace); font-size: small;"
          ),
          br(),
          shinyjs::disabled(
            actionButton(
              inputId = ns("btn_analysis_results"),
              label = "Show analysis results",
              class = "btn-primary"
            )
          )
        )),

        ## Results layout - hidden until analysis completes
        shinyjs::hidden(div(
          id = ns("analysis_results"),

          ## ++ ##
          ## -- Header: survey context, then measure by dimensions ------------
          ## ++ ##
          div(
            class = "analysis-header",
            div(class = "analysis-context", textOutput(ns("analysis_context"), inline = TRUE)),
            h3(class = "analysis-heading", textOutput(ns("analysis_heading"), inline = TRUE))
          ),

          ## ++ ##
          ## -- Toolbar: measure, means or totals, filters, export -----------
          ## ++ ##
          div(
            class = "analysis-controls",
            div(
              class = "analysis-toolbar",
              div(
                class = "analysis-toolbar-measure",
                selectInput(ns("analysis_sel_measure"), "Measure", choices = NULL, selected = NULL)
              ),
              ## Means or totals, for both the results table and the figure
              div(
                id = ns("analysis_table_source_wrap"),
                class = "seg-control analysis-toolbar-estimates",
                shinyWidgets::radioGroupButtons(
                  inputId   = ns("analysis_table_source"),
                  status    = "segment",
                  label     = "Estimates",
                  choices   = c("Means (per ha)" = "MEANS", "Totals" = "TOTALS"),
                  selected  = "MEANS",
                  size      = "sm",
                  justified = TRUE
                )
              ),
              ## Filter chip: shows the filter state, opens the dimension filters below
              div(
                tags$label(class = "form-label", "Filters"),
                tags$button(
                  type = "button",
                  class = "btn filter-chip",
                  `data-bs-toggle` = "collapse",
                  `data-bs-target` = paste0("#", ns("analysis_filters_panel")),
                  `aria-expanded` = "false",
                  `aria-controls` = ns("analysis_filters_panel"),
                  bsicons::bs_icon("funnel"),
                  textOutput(ns("analysis_filter_summary"), inline = TRUE)
                )
              ),
              ## Export menu: table, figure and report downloads in one place
              div(
                class = "dropdown analysis-toolbar-export",
                tags$button(
                  type = "button",
                  class = "btn btn-primary btn-icon dropdown-toggle",
                  `data-bs-toggle` = "dropdown",
                  `data-bs-auto-close` = "outside",
                  `data-bs-popper-config` = '{"strategy":"fixed"}',
                  `aria-expanded` = "false",
                  "Export"
                ),
                div(
                  class = "dropdown-menu dropdown-menu-end export-menu",
                  div(
                    class = "export-section",
                    div(class = "export-title", "Results table"),
                    div(
                      class = "export-row",
                      actionButton(ns("analysis_table_copy"), "Copy visible table", class = "btn-primary btn-sm"),
                      downloadButton(ns("analysis_table_download"), "Full table (CSV)", class = "btn-primary btn-sm")
                    )
                  ),
                  div(
                    class = "export-section",
                    div(class = "export-title", "Figure (PNG)"),
                    div(
                      class = "export-row",
                      div(
                        class = "seg-control seg-inline",
                        style = "width: 140px;",
                        shinyWidgets::radioGroupButtons(
                          inputId   = ns("plot_download_theme"),
                          status    = "segment",
                          label     = NULL,
                          choices   = c("Light" = "light", "Dark" = "dark"),
                          selected  = "light",
                          size      = "sm",
                          justified = TRUE
                        )
                      ),
                      downloadButton(ns("analysis_plot_download"), "Download", class = "btn-primary btn-sm")
                    )
                  ),
                  div(
                    class = "export-section",
                    div(class = "export-title", "Report"),
                    div(
                      class = "export-row",
                      div(
                        class = "seg-control seg-inline",
                        style = "width: 140px;",
                        shinyWidgets::radioGroupButtons(
                          inputId   = ns("analysis_report_format"),
                          status    = "segment",
                          label     = NULL,
                          choices   = c("Word" = "docx", "HTML" = "html"),
                          selected  = "docx",
                          size      = "sm",
                          justified = TRUE
                        )
                      ),
                      downloadButton(ns("analysis_report_download"), "Download", class = "btn-primary btn-sm")
                    )
                  ),
                  ## Shown when the figure cannot be drawn (figure and report unavailable)
                  shinyjs::hidden(div(
                    id = ns("export_unavailable_note"),
                    class = "export-note text-warning",
                    bsicons::bs_icon("exclamation-triangle"),
                    " ", i18n$t(.tr$tool_export_unavailable)
                  ))
                )
              )
            ),
            ## Dimension filters, opened from the filter chip
            div(
              id = ns("analysis_filters_panel"),
              class = "collapse",
              uiOutput(ns("analysis_extra_filters"))
            )
          ),

          ## ++ ##
          ## -- Row 1: results table -----------------------------------------
          ## ++ ##
          card(
            full_screen = TRUE,
            card_header("Results table"),
            DT::DTOutput(ns("analysis_table"))
          ),

          ## ++ ##
          ## -- Row 2: figure options (5/12) and figure (7/12) ---------------
          ## ++ ##
          layout_columns(
            col_widths = breakpoints(sm = 12, lg = c(4, 8)),
            fill = FALSE,
            card(
              card_header("Figure options"),
              selectInput(ns("plot_dim"), "X-axis dimension", choices = NULL),
              selectizeInput(
                ns("plot_fill"),
                "Group by",
                choices = NULL,
                options = list(placeholder = "-- none --", allowEmptyOption = TRUE)
              ),
              selectizeInput(
                ns("plot_facet"),
                "Facet by",
                choices = NULL,
                options = list(placeholder = "-- none --", allowEmptyOption = TRUE)
              ),
              layout_column_wrap(
                width = "140px",
                fill  = FALSE,
                checkboxInput(ns("plot_errbar"), "Error bars", value = TRUE),
                checkboxInput(ns("plot_flip"), "Swap axis", value = FALSE),
                checkboxInput(ns("plot_wrap_labels"), "Wrap labels", value = TRUE),
                checkboxInput(ns("plot_hide_legend"), "Hide legend", value = FALSE)
              )
            ),

            ## Figure of the selected estimates (means or totals)
            card(
              full_screen  = TRUE,
              card_header(textOutput(ns("analysis_plot_title"), inline = TRUE)),
              ## What to change in Figure options when the figure cannot be drawn
              uiOutput(ns("analysis_plot_guidance")),
              ## Light and dark versions stacked: CSS shows the dark one on top in dark
              ## mode, so the theme toggle is instant (no server redraw)
              div(
                id = ns("analysis_plot_area"),
                class = "plot-themed",
                plotOutput(ns("analysis_plot_light"), height = "400px"),
                div(class = "plot-themed-dark", plotOutput(ns("analysis_plot_dark"), height = "400px"))
              )
            )
          )
          ## ++ ##

        ))
        ## ++ ##

        ## $$$
      )

    ) ## END navset_card_tab()

  ) ## END tagList

} ## END module UI function
