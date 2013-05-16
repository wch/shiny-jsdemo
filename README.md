Demo of Shiny integration with third-party Javascript libraries
===============================================================

This Shiny app demonstrates how to integrate with Javascript libraries. A live version is here: http://glimmer.rstudio.com/winstontest/dashboard/

The external Javascript libraries used in this app include:

* [Gridster](http://gridster.net/)
* [JustGage](http://justgage.com/)
* [Highcharts](http://www.highcharts.com/)

Here's how to run the app:

```
# If necessary, install devtools
# install.packages("devtools")

# Install shiny-gridster package
devtools::install_github("shiny-gridster", "wch")

# Install the latest development version of shiny
devtools::install_github("shiny", "rstudio")

library(shiny)
runGitHub("shiny-jsdemo", "wch")
```


## How the libraries are used in this app

This app illustrates several different ways of integrating Javascript code into Shiny apps. They range from modular (putting Javascript and R wrapper code in an R package), to quick-and-dirty (putting Javascript inline in ui.r).

### Gridster

Gridster is used via the [shinyGridster](https://github.com/wch/shiny-gridster) R package. This package abstracts away the HTML- and Javascript-related details for using Gridster, so users of the package can simply write R and Shiny code. Creating an R package the best method if you want to make the Javascript code modular and easily reusable, but it also takes the most work.

The Gridster grid and items are created in ui.r with code like this, where `...` is simply a placeholder for other Shiny HTML elements:

```
gridster(width = 250, height = 250,
  gridsterItem(col = 1, row = 1, sizex = 1, sizey = 1, ...),
  gridsterItem(col = 2, row = 1, sizex = 2, sizey = 1, ...),
  ...
)
```


### JustGage

JustGage is added in a quick-and-dirty way. The Javascript library files are included as part of this app, instead of being wrapped up in a separate R package, and some Javascript initialization code is put inline in ui.r.

The JustGage library consists of two Javascript files in /www/js/, raphael.js and justgage.js. These files are included in ui.r. After these files are included, there are two steps to add the gauge. First, a div is added to the page:

```
  tags$div(id = "live_gauge", style = "width:250px; height:200px")
```

Then a block of Javascript code is added inline to ui.r, which initializes that div when the page is loaded.

To update when data is sent from the server, a custom message handler is added which receives the JSON packet and does the appropriate thing with it. This is the Javascript code:

```js
// Handle messages for setting gauge
Shiny.addCustomMessageHandler("setGauge",
  function(message) {
    gauges[message.name].refresh(message.value);
  }
);
```

And here is the corresponding code that sends the data (from server.r):

```
observe({
  running_mean <- mean(last(values(), n = 10))

  session$sendCustomMessage(
    type = "setGauge",
    message = list(name = "live_gauge", value = round(running_mean, 1))
  )
})
```

### Highcharts

The way Highcharts is used in this app is similar to the way JustGage is used. The main difference is that instead of being put inline in ui.r, the Javascript initialization code is contained in a separate file, www/initchart.js.

To place the chart, a div is added to the page in ui.r:

```js
tags$div(id = "live_highchart",
  style="min-width: 200px; height: 230px; margin: 0 auto"
)
```

Then the chart is initialized with code in initchart.js.

To update values that are sent from the server, a custom message handler is registered (in initchart.js):

```js
Shiny.addCustomMessageHandler("updateHighchart",
  function(message) {
    // Find the chart with the specified name
    var series = $("#" + message.name).highcharts().series[0];

    // Add a new point
    series.addPoint([Number(message.x), Number(message.y)], true, true);
  }
);
```

And here is the corresponding code that sends the values, in server.r:

```
observe({
  session$sendCustomMessage(
    type = "updateHighchart",
    message = list(
      # Name of chart to update
      name = "live_highchart",
      # Send UTC timestamp as a string so we can specify arbitrary precision
      # (large numbers get converted to scientific notation and lose precision)
      x = sprintf("%15.3f", as.numeric(Sys.time()) * 1000),
      y = last(values())
    )
  )
})
```


### Status panel

The status panel (which starts out with the text "OK") is more modularized than JustGage or Highchart in this app.

The code that generates the div in ui.r is contained in dashwidgets.r. So in ui.r, only this code is needed to create the status widget:

```
  statusOutput(outputId = 'status')
```

Instead of using a custom message handler, it does things in a more proper Shiny way, with a Shiny output binding. The code for this is in shiny_status_binding.js. The `renderValue()` method of the output binding handles the message from the server and updates the text.

```js
  renderValue: function(el, data) {
    var $el = $(el);
    $el.children('.grid_bigtext').text(data.text || '');
    $el.children('p').text(data.subtext || '');

    var $grid = $el.parent('li.gs_w');

    // Remove the previously set grid class
    var lastGridClass = $el.data('gridClass');
    if (lastGridClass)
      $grid.removeClass(lastGridClass);

    $el.data('gridClass', data.gridClass);

    if (data.gridClass) {
      $grid.addClass(data.gridClass);
    }
```


In server.r, the value is sent to the client with code like this:

```
output$status <- reactive({
  running_mean <- mean(last(values(), n = 10))

  if (running_mean > 200)
    list(text="Past limit", gridClass="alert")
  else
    list(text="OK", subtext="Below threshold (200)")
})
```

Again, compared to the use of JustGage and Highcharts in this app, this is a more proper Shiny way of sending data from the server to the client.


License information
===================

* [Gridster](http://gridster.net/) is released under the MIT license.
* [shinyGridster](https://github.com/wch/shiny-gridster), the R package wrapping up Gridster for use with Shiny, is released under the GPL-3 license.
* [JustGage](http://justgage.com/) is released under the MIT license.
* [Highcharts](http://www.highcharts.com/) is free for non-commercial use under the [CC BY-NC 3.0 license](http://creativecommons.org/licenses/by-nc/3.0/). For commercial use, a license must be purchased from [http://www.highcharts.com/](http://www.highcharts.com/).
* All other code in this demo app is licensed under the [CC0 1.0 license](http://creativecommons.org/publicdomain/zero/1.0/), which puts it in the public domain (or equivalent, depending on your local laws).
