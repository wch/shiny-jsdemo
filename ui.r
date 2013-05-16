library(shinyGridster)

source('dashwidgets.r', local=TRUE)

shinyUI(bootstrapPage(
  tags$head(
    tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),

    # For JustGage, http://justgage.com/
    tags$script(src = 'js/raphael.2.1.0.min.js'),
    tags$script(src = 'js/justgage.1.0.1.min.js'),

    # For Highcharts, http://www.highcharts.com/
    tags$script(src = 'js/highcharts.js'),

    # For the Shiny output binding for status text
    tags$script(src = 'shiny_status_binding.js')
  ),

  h1("Shiny + Gridster + JustGage + Highcharts"),

  gridster(width = 250, height = 250,
    gridsterItem(col = 1, row = 1, sizex = 1, sizey = 1,

      sliderInput("rate", "Rate of growth:",
        min = -0.25, max = .25, value = .02, step = .01),

      sliderInput("volatility", "Volatility:",
        min = 0, max = .5, value = .25, step = .01),

      sliderInput("delay", "Delay (ms):",
        min = 250, max = 5000, value = 3000, step = 250),

      tags$p(
        tags$br(),
        tags$a(href = "https://github.com/wch/shiny-jsdemo", "Source code")
      )
    ),
    gridsterItem(col = 2, row = 1, sizex = 2, sizey = 1,
      tags$div(id = "live_highchart",
        style="min-width: 200px; height: 230px; margin: 0 auto"
      )
    ),
    gridsterItem(col = 1, row = 2, sizex = 1, sizey = 1,
      tags$div(id = "live_gauge", style = "width:250px; height:200px")
    ),
    gridsterItem(col = 2, row = 2, sizex = 1, sizey = 1,
      tags$div(class = 'grid_title', 'Status'),
      statusOutput('status')
    ),
    gridsterItem(col = 3, row = 2, sizex = 1, sizey = 1,
      plotOutput("plotout", height = 250)
    )
  ),

  # Can embed Javascript code directly into ui.r
  # This code initializes the gauge
  tags$script(HTML('
    // Wait for DOM ready before initializing gauge
    $(document).ready(function() {
  
      var gauges = {};

      // Initialize gauge
      gauges.live_gauge = new JustGage({
        id: "live_gauge",
        value: 0,
        min: 0,
        max: 200,
        title: "Mean of last 10",
        label: "units"
      });

      // Handle messages for setting gauge
      Shiny.addCustomMessageHandler("setGauge",
        function(message) {
          gauges[message.name].refresh(message.value);
        }
      );
    })
  ')),

  # Can read Javascript code from a separate file
  # This code initializes the dynamic chart
  tags$script(src = "initchart.js")

))
