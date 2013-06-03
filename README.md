Demo of Shiny integration with third-party Javascript libraries
===============================================================

This Shiny app demonstrates how to integrate with Javascript libraries. A live version is here: http://glimmer.rstudio.com/winstontest/shiny-jsdemo/

The external Javascript libraries used in this app include:

* [Gridster](http://gridster.net/)
* [JustGage](http://justgage.com/)
* [Highcharts](http://www.highcharts.com/)

To run the app, you need to have the latest development version of Shiny installed.

After installing httpuv, install shinyGridster and Shiny:

```
# Get latest version of httpuv (needed for devel version of Shiny)
install.packages("httpuv")

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

Please keep in mind that this code is experimental, and so it does not necessarily reflect best practices.

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

JustGage is added in a somewhat modular way. The Javascript library files are included as part of this app, instead of being wrapped up in a separate R package, and some Javascript initialization code is put inline in ui.r.

The JustGage library consists of two Javascript files in /www/js/, raphael.js and justgage.js. These files are included in ui.r. 

To generate the appropriate HTML for inserting a JustGage on a web page, there's a function defined in dashwidgets.r, which emits the proper div tag:

```
justgageOutput <- function(outputId, width, height) {
  tags$div(id = outputId, class = "justgage_output", style = sprintf("width:%dpx; height:%dpx", width, height))
}
```

This is inserted in the web page in ui.r, like so:

```
justgageOutput("live_gauge", width=250, height=200)
```

An _output binding_ for JustGage is defined in justgage_binding.js. The output binding is an object with a set of methods that allow you to find and talk to the output objects.

Here is the most important method of that output binding, `renderValue()` (with some initialization bits removed). It receives messages from the server, and sets the value of the gauge based on the message:

```js
  renderValue: function(el, data) {
    $(el).data('gauge').refresh(data);
  }
```

To send data from the server, you simply assign a reactive expression to a value in the `output` object (from server.r):

```
# Set the value for the gauge
# When this reactive expression is assigned to an output object, it is
# automatically wrapped into an observer (i.e., a reactive endpoint)
output$live_gauge <- reactive({
  running_mean <- mean(last(values(), n = 10))
  round(running_mean, 1)
})
```

A function like `renderText()` could also be used instead of the reactive expression.


### Status panel

The status panel (which starts out with the text "OK") is modularized in a way that's similar to JustGage, except that there's no separate Javascript library for the status panel, because it employs just a small amount of Javascript.

The code that generates the div in ui.r is contained in dashwidgets.r:

```
statusOutput <- function(outputId) {
  tags$div(id=outputId, class="status_output",
           tags$div(class = 'grid_bigtext'),
           tags$p()
  )
}
```

In ui.r, this code is adds the div for the status widget to the page:

```
  statusOutput(outputId = 'status')
```

It also uses a custom output binding to handle values sent from the server. The code for this is in shiny_status_binding.js. The `renderValue()` method of the output binding handles the message from the server and updates the text.

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


In server.r, the value is sent to the client by assigning a reactive expression to the output object:

```
output$status <- reactive({
  running_mean <- mean(last(values(), n = 10))

  if (running_mean > 200)
    list(text="Past limit", gridClass="alert")
  else
    list(text="OK", subtext="Below threshold (200)")
})
```


### Highcharts

The Highcharts library is added to this app in a quick-and-dirty way. Instead of using an output binding to handle messages from the server, it uses a custom message handler.

To place the chart, a div is added to the page in ui.r:

```js
tags$div(id = "live_highchart",
  style="min-width: 200px; height: 230px; margin: 0 auto"
)
```

(With the JustGage example, we wrapped up the HTML-generating code in another function, but in this case, we put it directly into ui.r.)

The chart is initialized when the page loads, with code in www/initchart.js.

To update the graph when new values are sent from the server, a custom message handler is registered with Shiny (in initchart.js):

```js
Shiny.addCustomMessageHandler("updateHighchart",
  function(message) {
    // Find the chart with the specified name
    var chart = $("#" + message.name).highcharts();
    var series = chart.series;

    // Add a new point
    series[0].addPoint([Number(message.x), Number(message.y0)], false, true);
    series[1].addPoint([Number(message.x), Number(message.y1)], false, true);
    chart.redraw();
  }
);
```

Why not use an output binding, as with the previous examples? There are two reasons. The first reason is that, in the previous cases, the output value sent from the server represents the entire state of the object; for the JustGage, it's a numeric value, and for the status panel, it's a list-like data structure that specifies the entire state of the panel. For the Highchart, the server is actually sending the latest value, but the state of the object includes several previous values as well. So although it's possible to make an output binding that allows the client side to keep more state information than is sent each time from the server, that is something that is at odds with the conceptual framework that Shiny rests on.

The second reason that the Highchart doesn't use an output binding is much less principled: the custom message handler is a little simpler to code than a proper output binding.


Here is the corresponding code that sends the values from the server to the client (in server.r):

```
# Update the latest value on the graph
# Send custom message (as JSON) to a handler on the client
observe({
  session$sendCustomMessage(
    type = "updateHighchart",
    message = list(
      # Name of chart to update
      name = "live_highchart",
      # Send UTC timestamp as a string so we can specify arbitrary precision
      # (large numbers get converted to scientific notation and lose precision)
      x = sprintf("%15.3f", as.numeric(Sys.time()) * 1000),
      # Most recent value
      y0 = last(values()),
      # Smoothed value (average of last 10)
      y1 = mean(last(values(), n = 10))
    )
  )
})
```


License information
===================

* [Gridster](http://gridster.net/) is released under the MIT license.
* [shinyGridster](https://github.com/wch/shiny-gridster), the R package wrapping up Gridster for use with Shiny, is released under the GPL-3 license.
* [JustGage](http://justgage.com/) is released under the MIT license.
* [Highcharts](http://www.highcharts.com/) is free for non-commercial use under the [CC BY-NC 3.0 license](http://creativecommons.org/licenses/by-nc/3.0/). For commercial use, a license must be purchased from [http://www.highcharts.com/](http://www.highcharts.com/).
* All other code in this demo app is licensed under the [CC0 1.0 license](http://creativecommons.org/publicdomain/zero/1.0/), which puts it in the public domain (or equivalent, depending on your local laws).
