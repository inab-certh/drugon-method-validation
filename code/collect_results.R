analysisDirs <- list.dirs(
  file.path(outputFolder, "analyses"),
  recursive = FALSE
)

analysisRefCombined <- list.files(
  path = file.path(analysisDirs, "export"),
  pattern = "analysisRef.*csv",
  full.names = TRUE
) |>
  purrr::map_dfr(readr::read_csv, show_col_types = FALSE)

estimatesCombined <- list.files(
  path = file.path(analysisDirs, "export"),
  pattern = "estimates.*csv",
  full.names = TRUE
) |>
  purrr::map_dfr(readr::read_csv, show_col_types = FALSE)

metrics <- list()

for (i in seq_along(analysisDirs)) {

  exportFolder <- file.path(analysisDirs[i], "export")

  metrics[[i]] <- MethodEvaluation::computeOhdsiBenchmarkMetrics(
    exportFolder = exportFolder,
    mdrr = 5,
    stratum = "All",
    trueEffectSize = "Overall",
    calibrated = FALSE,
    comparative = FALSE
  )
 
}

result <- dplyr::bind_rows(metrics)

executionMetricsFile <- file.path(outputFolder, "executionMetrics.csv")
readr::write_csv(result, executionMetricsFile)
message(paste("Wrote metrics to", executionMetricsFile))
