library(SelfControlledCaseSeries)

multiThreadingSettings <- createDefaultSccsMultiThreadingSettings(
  parallel::detectCores() - 1
)

controlsFolder <- outputFolder
outputFolder <- file.path(outputFolder, "analyses/sccs")

if (!dir.exists(outputFolder)) dir.create(outputFolder, recursive = TRUE)
message(paste("Created directory:", outputFolder))

allControls <- readr::read_csv(
  file = file.path(controlsFolder, "allControls.csv"),
  show_col_types = FALSE
)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("omop_db_dbms"),
  server = Sys.getenv("omop_db_server"),
  user = Sys.getenv("omop_db_user"),
  password = Sys.getenv("omop_db_password"),
  pathToDriver = Sys.getenv("omop_db_driver")
)

getDbSccsDataArgs <- createGetDbSccsDataArgs(
  useCustomCovariates = FALSE,
  deleteCovariatesSmallCount = 0,
  exposureIds = unique(allControls |> pull(targetId)),
  maxCasesPerOutcome = 100000
)

createStudyPopulationArgs <- createCreateStudyPopulationArgs(
  naivePeriod = 0,
  firstOutcomeOnly = FALSE
)

covarExposureOfInt <- createEraCovariateSettings(
  label = "Exposure of interest",
  includeEraIds = "exposureId",
  start = 0,
  end = 0,
  endAnchor = "era end",
  profileLikelihood = TRUE,
  exposureOfInterest = TRUE
)

createSccsIntervalDataArgs1 <- createCreateSccsIntervalDataArgs(
  eraCovariateSettings = covarExposureOfInt
)

fitSccsModelArgs <- createFitSccsModelArgs()

sccsAnalysis1 <- createSccsAnalysis(
  analysisId = 3,
  description = "Simple SCCS",
  getDbSccsDataArgs = getDbSccsDataArgs,
  createStudyPopulationArgs = createStudyPopulationArgs,
  createIntervalDataArgs = createSccsIntervalDataArgs1,
  fitSccsModelArgs = fitSccsModelArgs
)

sccsAnalysisList <- list(sccsAnalysis1)

outcomeIds <- allControls |> pull(outcomeId) |> unique()
exposuresOutcomeList <- list()
for (i in seq_along(outcomeIds)) {
  subsetTargetIds <- allControls |>
    dplyr::filter(outcomeId == outcomeIds[i]) |>
    dplyr::pull(targetId)
  for (j in seq_along(subsetTargetIds)) {
    exposuresOutcome <- createExposuresOutcome(
      outcomeId = outcomeIds[i],
      exposures = list(createExposure(exposureId = subsetTargetIds[j], trueEffectSize = 1))
    )
    exposuresOutcomeList[[length(exposuresOutcomeList) + 1]] <- exposuresOutcome
  }
}

referenceTable <- runSccsAnalyses(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  exposureDatabaseSchema = cdmDatabaseSchema,
  exposureTable = "drug_era",
  outcomeDatabaseSchema = outcomeDatabaseSchema,
  outcomeTable = outcomeTable,
  outputFolder = outputFolder,
  combineDataFetchAcrossOutcomes = TRUE,
  exposuresOutcomeList = exposuresOutcomeList,
  sccsAnalysisList = sccsAnalysisList,
  sccsMultiThreadingSettings = multiThreadingSettings,
  controlType = "exposure"
)

sccsSummary <- getResultsSummary(outputFolder)

sccsSummary <- referenceTable |>
  dplyr::select(exposuresOutcomeSetId, exposureId) |>
  dplyr::left_join(sccsSummary, by = "exposuresOutcomeSetId")

summaryDir <- file.path(outputFolder, "sccsSummary.csv")
readr::write_csv(sccsSummary, summaryDir)
message(paste("Summary written in", summaryDir))

analysisRef <- data.frame(
  method = "SelfControlledCaseSeries",
  analysisId = sccsAnalysis1$analysisId,
  description = sccsAnalysis1$description,
  details = "",
  comparative = FALSE,
  nesting = FALSE,
  firstExposureOnly = FALSE
)

MethodEvaluation::packageOhdsiBenchmarkResults(
  estimates = sccsSummary |> dplyr::rename(c("targetId" = "exposureId")),
  controlSummary = allControls,
  analysisRef = analysisRef,
  databaseName = "PGH",
  exportFolder = file.path(outputFolder, "export")
)

message(paste("Results saved at:", file.path(outputFolder, "export")))
