
# Get time with millisecond accuracy
options(digits.secs=6)

shinyServer(function(input, output, session) {

  all_values <- 100  # Start with initial value 100
  max_length <- 80   # Keep a maximum of 80 values

  # Collect new values at timed intervals
  values <- reactive({
    # Set the delay to re-run this reactive expression
    invalidateLater(input$delay, session)

    # Generate a new number
    new_value <- isolate(last(all_values) * 
      (1 + input$rate + runif(1, min = -input$volatility, max = input$volatility)))

    # Append to all_values
    all_values <<- c(all_values, new_value)

    # Trim all_values to max_length, dropping values from beginning
    len <- length(all_values)
    if (len > max_length) {
      all_values <<- all_values[(1+len-max_length):len]
    }

    all_values
  })

  # The mean of the last 10 values
  running_mean <- reactive({
    vals <- values()
    len <- length(vals)

    if (len <= 10)  start <- 1
    else            start <- len - 10

    mean(vals[start:len])
  })    


  output$plotout <- renderPlot({
    hist(values(), col = "#cccccc",
      main = paste("Last", length(values()), "values"), xlab = NA)
  })

  output$status <- renderUI({
    if (last(running_mean()) > 400) {
      tags$div(class = 'grid_bigtext grid_alert', 'Past limit')
    } else {
      tagList(
        tags$div(class = 'grid_bigtext', 'OK'),
        tags$p('Below threshold (400)')
      )
    }
  })

  observe({
    session$sendCustomMessage(
      type = "setGauge", 
      message = list(name = "live_gauge", value = round(running_mean(), 1))
    )
  })

  observe({
    session$sendCustomMessage(
      type = "updateHighchart", 
      message = list(
        # Name of chart to update
        name = "live_highchart",
        # Send UTC timestamp as a string so we can specify arbitrary precision
        # (large numbers get converted to scientific notation and lose precision)
        x = sprintf("%20f", as.numeric(Sys.time()) * 1000),
        y = last(values())
      )
    )
  })


})


# Return the last element in vector x
last <- function(x) {
  x[length(x)]
}
