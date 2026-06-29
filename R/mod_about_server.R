#' About module server function
#'
#' @noRd
mod_about_server <- function(id, rv) {

  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    output$dl_example <- downloadHandler(
      filename = function(){"OLAP_Shiny_demo.zip"},
      content  = function(file){file.copy(system.file("extdata/MAU_Shiny_(testi_4_chain).zip", package = "arenalytics"), file)}
    )


  }) ## END module server function

}
