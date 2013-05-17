statusOutput <- function(outputId) {
  tags$div(id=outputId, class="status_output",
           tags$div(class = 'grid_bigtext'),
           tags$p()
  )
}

justgageOutput <- function(outputId, width, height) {
  tags$div(id = outputId, class = "justgage_output", style = sprintf("width:%dpx; height:%dpx", width, height))
}
