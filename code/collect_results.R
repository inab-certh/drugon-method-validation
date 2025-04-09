outputFolder <- "./results"

analysisDirs <- list.dirs(
  file.path(outputFolder, "analyses"),
  recursive = FALSE
)

for (i in seq_along(analysisDirs)) {

  summaryFiles <- list.files(
    path = analysisDirs,
    pattern = "*Summary.csv",
    full.names = TRUE
  )

  summariesCombined <- summaryFiles |>
    purrr::map_dfr(readr::read_csv)

}

estimates <- summariesCombined |>
  dplyr::select(analysisId, exposureId, exposureId, outcomeId, logRr, seLogRr)

estimates <- readr::read_csv(file.path(outputFolder, "sccSummary.csv"))
estimates <- data.frame(
  analysisId = estimates$analysisId,
  targetId = estimates$exposureId,
  outcomeId = estimates$outcomeId,
  logRr = estimates$logRr,
  seLogRr = estimates$seLogRr,
  ci95Lb = estimates$irrLb95,
  ci95Ub = estimates$irrUb95
)

analysisRef <- data.frame(
  method = "SelfControlledCohort",
  analysisId = c(1, 2),
  description = c(
    "Length of exposure",
    "30 days of each exposure"
  ),
  details = "",
  comparative = FALSE,
  nesting = FALSE,
  firstExposureOnly = FALSE
)

allControls <- read.csv(file.path(outputFolder, "allControls.csv"))
packageOhdsiBenchmarkResults(
  estimates = estimates,
  controlSummary = allControls,
  analysisRef = analysisRef,
  databaseName = databaseName,
  exportFolder = file.path(outputFolder, "export")
)
