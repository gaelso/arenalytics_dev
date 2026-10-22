<!-- badges: start -->
[![R-CMD-check](https://github.com/openforis/arenalytics/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/openforis/arenalytics/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

# ArenaLytics

Analytics and visualizations for OpenForis Arena data

Run at: https://openforis-shiny.shinyapps.io/arenalytics/

or install and run locally in a Rstudio instance with:

```         
if (!require(remotes)) install.packages("remotes")
if (!require(arenalytics)) remotes::install_github("openforis/arenalytics", upgrade="never")

arenalytics::shiny_run_arenalytics()
```

For development version see: https://github.com/gaelso/arenalytics_dev

or install locally 

```
remotes::install_github("gaelso/arenalytics_dev", ref = "dev")
arenalytics::shiny_run_arenalytics()
```


*Installing the development version is not recommended and may not work as expected, including bugs in the application and/or wrong estimation of survey results.*
