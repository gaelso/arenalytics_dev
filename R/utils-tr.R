#' Translation keys
#'
#' Returns a named list of all i18n translation keys used in the app.
#' Each value must exactly match a key present in `inst/assets/translations.json`.
#'
#' @return A named list of character strings.
#' @keywords internal
#' @noRd
.tr_keys <- function() {
  list(
    ## main function
    app_title = "Analytical Dashboard for National Forest Inventories and Complex Surveys", ## 2nd line of the header title, under {ArenaLytics}
    nav_home  = "Home",
    nav_tool  = "Tool",
    nav_about = "About",

    ## Home UI
    hero_title = "Turn field data into report-ready figures and statistics",
    hero_txt = "Create a survey in Open Foris Arena, collect the data and come here to explore it, gain insights and produce reliable estimates.",
    hero_btn = "Get Started",
    hero_photo_credit = "Tropical rainforest, Kaeng Krung National Park, Thailand (Photo: Gael Sola)",
    feat1_p1 = "A dashboard shinyApp, ArenaLytics, shipped as a R package, unlocking the powerful statistics of R with the visual convenience of dashboards.",
    feat1_p2 = "For more details about the app developement or if any issue, find us on:",
    feat1_p3 = "Start playing with your data in the Tool section!",
    feat1_btn = "Here",
    feat2_p1 = "ArenaLytics is tailored to work with",
    feat2_p2 = "Open Foris Arena helps you create a survey, collect and clean data, and develop a processing chain for calculating additional variables from your data.",
    feat2_p3 = "The outcome of this process is a ZIP file of semi-aggregated data that will serve as input here.",
    feat3_title = "Need help?",
    feat3_p1 = "Tutorials, examples and additional resources can help you harness the analytical power of ArenaLytics.",
    feat3_p2 = "The full package documentation, as well as case studies and tutorials have been developed to help you navigate through the dashboard capabilities.",
    feat3_p3 = "For more information, go to:",
    feat3_btn = "About", ## Not pasted twice in assets/translations.json

    ## Tool UI
    ac1_title = "Load ZIP file",
    ac1_p1 = "The dashboard requires a ZIP file that is produced by running the processing chain from your Open Foris Arena survey in Rstudio (local or online).",
    ac1_p2 = "Once this file is produced, upload it here:",
    #ac1_input1 = "Browse...",
    #ac1_input2 = "No file selected",
    ac1_msg_nodata = "No data uploaded.",
    ac1_msg_ok = "Data structure OK.",
    ac1_msg_err = "Incorrect data uploaded.",
    ac1_btn = "Read data",
    cfg_psu_adjust = "Conservative estimate of standard error.",
    cfg_psu_remove = "Permissive estimate of standard error.",
    cfg_cm_fast    = "Computes all measures together.",
    cfg_cm_safe    = "Computes measures individually, keeps going when some measures fail.",
    tool_fig_unavailable = "To display the figure, assign these dimensions to Group by or Facet by in Figure options, or filter them to one class:",
    tool_export_unavailable = "Figure and report unavailable: set up the figure first.",

    ## About UI
    about_title = "About ArenaLytics",
    about_lead = "ArenaLytics is an analytical dashboard for data collected and processed with Open Foris Arena. It turns survey results into estimates, tables, figures and reports on demand, without the need to define every output in advance.",
    about_how_title = "How it works",
    about_how_intro = "ArenaLytics is the last step of a four-step workflow. The first three steps take place in Open Foris Arena.",
    about_step1_title = "Design the survey",
    about_step1_txt = "Create the survey in Open Foris Arena: entities, attributes, categories, taxonomies and the sampling design.",
    about_step2_title = "Collect the data",
    about_step2_txt = "Field teams enter the data with Arena Mobile, online or offline, or with the Arena web form.",
    about_step3_title = "Process the data",
    about_step3_txt = "Run the processing chain in RStudio to compute result variables, such as volume, biomass and carbon stocks. Arena then exports a minimum area unit (MAU) ZIP file.",
    about_step4_title = "Analyse with ArenaLytics",
    about_step4_txt = "Upload the MAU ZIP file, select the inputs and run the analysis. Review the estimates, then export tables, figures and a report.",
    about_flow_title = "Workflow in detail",
    about_flow_mau = "MAU ZIP file",
    about_flow_load = "Load and check",
    about_flow_insights = "Explore insights",
    about_flow_inputs = "Select inputs",
    about_flow_config = "Configure and run",
    about_flow_review = "Review and export",
    about_flow_btn = "Detailed workflow",
    about_manual_btn = "User manual",
    about_context_title = "Context",
    about_of_txt = "Open Foris is a set of free and open-source software tools for forest and land monitoring, offered by the Food and Agriculture Organization of the United Nations (FAO). It aims to make monitoring accessible, transparent and collaborative. The tools cover field data collection, visual interpretation, data management and geospatial analysis.",
    about_ofa_txt = "Open Foris Arena is a cloud-based platform to design surveys and to collect, manage and process field data. It supports multilingual and multicycle surveys, offline data collection with Arena Mobile, and statistical processing in RStudio.",
    about_al_txt = "ArenaLytics was developed for national forest inventories and other sample-based surveys. It addresses a common challenge of these surveys: producing reliable statistics from large and complex datasets. Users choose the measures, dimensions and filters they need, and the dashboard computes means, totals and their sampling errors on demand.",
    about_al_link = "Source code on GitHub",
    about_demo_title = "Demo dataset",
    about_demo_intro = "Use the demo dataset to try the dashboard before working with your own survey. It is a demonstration forest inventory that follows the Arena forest inventory template (Template B): clusters of plots, with several entities measured in each plot.",
    about_demo_howto = "How to use it",
    about_demo_s1 = "Download the demo dataset.",
    about_demo_s2 = "Open the Tool page and upload the ZIP file in step 1, Load ZIP file.",
    about_demo_s3 = "Select the inputs, configure the analysis and select Run analysis.",
    about_demo_btn = "Download demo dataset",
    about_fact_design = "Sampling design",
    about_fact_design_val = "Stratified random sampling, two strata",
    about_fact_bu = "Base unit",
    about_fact_bu_val = "Plot",
    about_fact_sample = "Samples",
    about_fact_sample_val = "167 plots in 44 clusters, across three provinces",
    about_ex_entities = "Example entities",
    about_ex_entities_val = "Tree, deadwood, stump",
    about_ex_dims = "Example dimensions",
    about_ex_dims_val = "Forest type, land use, tree DBH (10 cm classes), species",
    about_ex_measures = "Example measures",
    about_ex_measures_val = "Number of trees, basal area, volume, carbon",
    about_overview_title = "Data overview",
    about_struct_title = "Under the hood",
    about_pkg_title = "Package",
    about_pkg_version = "Version",
    about_pkg_licence = "Licence",
    about_pkg_authors = "Authors",
    about_pkg_maintainer = "maintainer",
    about_pkg_source = "Source code",
    about_pkg_doc = "Documentation",
    about_pkg_install = "Install and run ArenaLytics in R (recommended):",
    about_pkg_online = "Open the online version",
    about_pkg_offline_pre = "An",
    about_pkg_offline_link = "offline installation bundle",
    about_pkg_offline_post = "is available for computers without internet access.",
    about_dep_title = "Dependencies",
    about_dep_intro = "ArenaLytics is an R package built with Shiny. It relies on the following packages.",
    about_dep_ui = "Interface",
    about_dep_data = "Data preparation",
    about_dep_stats = "Survey statistics",
    about_dep_report = "Figures and reports",
    about_cases_title = "Use cases and stories",
    about_cases_soon = "Coming soon.",
    about_dev_title = "Latest developments",
    about_dev_next = "In the pipeline",
    about_dev_next1 = "Handling of additional complex surveys, panelization and ratio estimators.",
    about_dev_next2 = "Use-case demonstrations.",
    about_dev_oct = "October 2026",
    about_dev_oct3 = "New analysis setup: separate steps to select the inputs and configure the analysis, with switches and dimension chips.",
    about_dev_oct4 = "Category dimensions keep the order defined in the survey in tables, figures and filters.",
    about_dev_oct6 = "Updated package dependencies for online deployment.",
    about_dev_link = "Full changelog",

    ## FAO footer: link labels as on the fao.org footer
    footer_contact      = "Contact us",
    footer_terms        = "Terms and Conditions",
    footer_privacy      = "Data protection and privacy",
    footer_scam         = "Scam Alert",
    footer_misconduct   = "Report Misconduct",
    footer_transparency = "Transparency and accountability",
    footer_credit       = "Developed for"




  )
}
