# Get time with millisecond accuracy
options(digits.secs=6)

shinyServer(function(input, output, session) {

  all_values <- 100  # Start with an initial value 100
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

    # Trim all_values to max_length (dropping values from beginning)
    all_values <<- last(all_values, n = max_length)

    all_values
  })


  # Generate histogram
  output$plotout <- renderPlot({
    hist(values(), col = "#cccccc",
      main = paste("Last", length(values()), "values"), xlab = NA)
  })

  # Set the value for the gauge
  output$live_gauge <- reactive({
    running_mean <- mean(last(values(), n = 10))
    round(running_mean, 1)
  })

  # Output the status text ("OK" vs "Past limit")
  # When this reactive expression is assigned to an output object, it is
  # automatically wrapped into an observer (i.e., a reactive endpoint)
  output$status <- reactive({
    running_mean <- mean(last(values(), n = 10))
    if (running_mean > 200)
      list(text="Past limit", gridClass="alert")
    else if (running_mean > 150)
      list(text="Warn", subtext = "Mean of last 10 approaching threshold (200)",
           gridClass="warning")
    else
      list(text="OK", subtext="Mean of last 10 below threshold (200)")
  })


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
        y = last(values())
      )
    )
  })

})


# Return the last n elements in vector x
last <- function(x, n = 1) {
  start <- length(x) - n + 1
  if (start < 1)
    start <- 1

  x[start:length(x)]
}
