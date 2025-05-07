library(SelfControlledCohort)

controlsFolder <- outputFolder
outputFolder <- file.path(outputFolder, "analyses/scc")

if (!dir.exists(outputFolder)) dir.create(outputFolder, recursive = TRUE)
message(paste("Created directory:", outputFolder))

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("omop_db_dbms"),
  server = Sys.getenv("omop_db_server"),
  user = Sys.getenv("omop_db_user"),
  password = Sys.getenv("omop_db_password"),
  pathToDriver = Sys.getenv("omop_db_driver")
)

runSccArgs1 <- SelfControlledCohort::createRunSelfControlledCohortArgs(
  addLengthOfExposureExposed = TRUE,
  riskWindowStartExposed = 0,
  riskWindowEndExposed = 0,
  riskWindowEndUnexposed = -1,
  addLengthOfExposureUnexposed = TRUE,
  riskWindowStartUnexposed = -1,
  washoutPeriod = 0
)

sccAnalysis1 <- SelfControlledCohort::createSccAnalysis(
  analysisId = 1,
  description = "Length of exposure",
  runSelfControlledCohortArgs = runSccArgs1
)

runSccArgs2 <- createRunSelfControlledCohortArgs(
  addLengthOfExposureExposed = FALSE,
  riskWindowStartExposed = 0,
  riskWindowEndExposed = 30,
  riskWindowEndUnexposed = -1,
  addLengthOfExposureUnexposed = FALSE,
  riskWindowStartUnexposed = -30,
  washoutPeriod = 0
)

sccAnalysis2 <- createSccAnalysis(
  analysisId = 2,
  description = "30 days of each exposure",
  runSelfControlledCohortArgs = runSccArgs2
)

sccAnalysisList <- list(sccAnalysis1, sccAnalysis2)

allControls <- readr::read_csv(
  file = file.path(controlsFolder, "allControls.csv"),
  show_col_types = FALSE
)
eos <- list()
for (i in 1:nrow(allControls)) {
  eos[[length(eos) + 1]] <- SelfControlledCohort::createExposureOutcome(
    exposureId = allControls$targetId[i],
    outcomeId = allControls$outcomeId[i]
  )
}

sccResult <- SelfControlledCohort::runSccAnalyses(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  oracleTempSchema = oracleTempSchema,
  exposureTable = "drug_era",
  outcomeDatabaseSchema = outcomeDatabaseSchema,
  outcomeTable = outcomeTable,
  sccAnalysisList = sccAnalysisList,
  exposureOutcomeList = eos,
  outputFolder = outputFolder,
  analysisThreads = 4,
  computeThreads = 2
)

sccSummary <- SelfControlledCohort::summarizeAnalyses(sccResult, outputFolder)

summaryDir <- file.path(outputFolder, "sccSummary.csv")
readr::write_csv(sccSummary, summaryDir)
message(paste("Summary written in", summaryDir))

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

estimates <- data.frame(
  analysisId = sccSummary$analysisId,
  targetId = sccSummary$exposureId,
  outcomeId = sccSummary$outcomeId,
  logRr = sccSummary$logRr,
  seLogRr = sccSummary$seLogRr,
  ci95Lb = sccSummary$irrLb95,
  ci95Ub = sccSummary$irrUb95
)

MethodEvaluation::packageOhdsiBenchmarkResults(
  estimates = estimates,
  controlSummary = allControls,
  analysisRef = analysisRef,
  databaseName = "PGH",
  exportFolder = file.path(outputFolder, "export")
)

# MethodEvaluation::computeOhdsiBenchmarkMetrics(
#   exportFolder = file.path(outputFolder, "export"),
#   mdrr = 5,
#   stratum = "All",
#   trueEffectSize = "Overall",
#   calibrated = FALSE,
#   comparative = FALSE
# )
