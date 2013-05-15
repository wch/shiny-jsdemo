statusOutput <- function(outputId) {
  tags$div(id=outputId, class="status_output",
           tags$div(class = 'grid_bigtext'),
           tags$p()
  )
}
