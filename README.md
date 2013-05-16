# Demo of Shiny integration with third-party Javascript libraries

This Shiny app demonstrates how to integrate with Javascript libraries. A live version is here: http://glimmer.rstudio.com/winstontest/dashboard/

The external Javascript libraries used in this app include:

* [Gridster](http://gridster.net/)
* [JustGage](http://justgage.com/)
* [Highcharts](http://www.highcharts.com/)

Here's how to run the app:

```R
# If necessary, install devtools
# install.packages("devtools")

# Install shiny-gridster package
devtools::install_github("shiny-gridster", "wch")

# Install the latest development version of shiny
devtools::install_github("shiny", "rstudio")

library(shiny)
runGitHub("shiny-jsdemo", "wch")
```

## License information

* [Gridster](http://gridster.net/) is released under the MIT license.
* [JustGage](http://justgage.com/) is released under the MIT license.
* [Highcharts](http://www.highcharts.com/) is free for non-commercial use under the [CC BY-NC 3.0 license](http://creativecommons.org/licenses/by-nc/3.0/). For commercial use, a license must be purchased from [http://www.highcharts.com/](http://www.highcharts.com/)
* All other code in this demo app may be used without restriction. 
