library(MethodEvaluation)
# library(SelfControlledCaseSeries)

message("\n ---- Connecting")
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("omop_db_dbms"),
  server = Sys.getenv("omop_db_server"),
  user = Sys.getenv("omop_db_user"),
  password = Sys.getenv("omop_db_password"),
  pathToDriver = Sys.getenv("omop_db_driver")
)

message("\n ---- Creating reference cohorts")

MethodEvaluation::createReferenceSetCohorts(
  connectionDetails = connectionDetails,
  oracleTempSchema = oracleTempSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  outcomeDatabaseSchema = outcomeDatabaseSchema,
  outcomeTable = outcomeTable,
  nestingDatabaseSchema = nestingCohortDatabaseSchema,
  nestingTable = nestingCohortTable,
  referenceSet = "ohdsiMethodsBenchmark",
  workFolder = outputFolder
)
message("\n ---- Finished createRefernceSetCohorts")

message("\n ---- Synthesizing positive controls")
synthesizeReferenceSetPositiveControls(
  connectionDetails = connectionDetails,
  oracleTempSchema = oracleTempSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  outcomeDatabaseSchema = outcomeDatabaseSchema,
  outcomeTable = outcomeTable,
  maxCores = 10,
  workFolder = outputFolder,
  summaryFileName = file.path(
    outputFolder,
    "allControls.csv"
  ),
  referenceSet = "ohdsiMethodsBenchmark"
)

# =============================
# SCCS anlaysis
# =============================

# getDbSccsDataArgs <- createGetDbSccsDataArgs(
#   useCustomCovariates = FALSE,
#   deleteCovariatesSmallCount = 100,
#   exposureIds = c(),
#   maxCasesPerOutcome = 100000
# )
# 
# createStudyPopulationArgs <- createCreateStudyPopulationArgs(
#   naivePeriod = 0,
#   firstOutcomeOnly = FALSE
# )
# 
# covarExposureOfInt <- createEraCovariateSettings(
#   label = "Exposure of interest",
#   includeEraIds = "exposureId",
#   start = 1,
#   end = 0,
#   endAnchor = "era end",
#   profileLikelihood = TRUE,
#   exposureOfInterest = TRUE
# )
# 
# createSccsIntervalDataArgs1 <- createCreateSccsIntervalDataArgs(
#   eraCovariateSettings = covarExposureOfInt
# )
# 
# fitSccsModelArgs <- createFitSccsModelArgs()
# 
# sccsAnalysis1 <- createSccsAnalysis(
#   analysisId = 3,
#   description = "Simple SCCS",
#   getDbSccsDataArgs = getDbSccsDataArgs,
#   createStudyPopulationArgs = createStudyPopulationArgs,
#   createIntervalDataArgs = createSccsIntervalDataArgs1,
#   fitSccsModelArgs = fitSccsModelArgs
# )
# 
# sccsAnalysisList <- list(sccsAnalysis1)
# 
# estimates <- readr::read_csv(file.path(outputFolder, "sccSummary.csv"))
# estimates <- data.frame(
#   analysisId = estimates$analysisId,
#   targetId = estimates$exposureId,
#   outcomeId = estimates$outcomeId,
#   logRr = estimates$logRr,
#   seLogRr = estimates$seLogRr,
#   ci95Lb = estimates$irrLb95,
#   ci95Ub = estimates$irrUb95
# )
# 
# analysisRef <- data.frame(
#   method = "SelfControlledCohort",
#   analysisId = c(1, 2),
#   description = c(
#     "Length of exposure",
#     "30 days of each exposure"
#   ),
#   details = "",
#   comparative = FALSE,
#   nesting = FALSE,
#   firstExposureOnly = FALSE
# )
# 
# allControls <- read.csv(file.path(outputFolder, "allControls.csv"))
# packageOhdsiBenchmarkResults(
#   estimates = estimates,
#   controlSummary = allControls,
#   analysisRef = analysisRef,
#   databaseName = databaseName,
#   exportFolder = file.path(outputFolder, "export")
# )
