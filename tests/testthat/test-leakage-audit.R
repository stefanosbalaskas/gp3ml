make_leakage_partitions <- function() {
  analysis <- data.frame(
    participant_id = c("P01", "P01", "P02", "P02"),
    trial_id = c("T01", "T02", "T03", "T04"),
    stimulus_id = c("S01", "S02", "S03", "S04"),
    outcome = c(0, 1, 0, 1),
    feature_a = c(1.1, 1.2, 1.3, 1.4),
    feature_b = c(2.1, 2.2, 2.3, 2.4),
    stringsAsFactors = FALSE
  )

  assessment <- data.frame(
    participant_id = c("P03", "P03", "P04", "P04"),
    trial_id = c("T05", "T06", "T07", "T08"),
    stimulus_id = c("S05", "S06", "S07", "S08"),
    outcome = c(1, 0, 1, 0),
    feature_a = c(1.5, 1.6, 1.7, 1.8),
    feature_b = c(2.5, 2.6, 2.7, 2.8),
    stringsAsFactors = FALSE
  )

  list(
    analysis = analysis,
    assessment = assessment
  )
}


run_leakage_audit <- function(
    partitions,
    generalization_target = "new_participants",
    predictors = c("feature_a", "feature_b"),
    participant_id = "participant_id",
    trial_id = "trial_id",
    stimulus_id = "stimulus_id",
    target_derived = character(),
    post_outcome = character()) {
  audit_gazepoint_ml_leakage(
    analysis = partitions$analysis,
    assessment = partitions$assessment,
    outcome = "outcome",
    predictors = predictors,
    participant_id = participant_id,
    trial_id = trial_id,
    stimulus_id = stimulus_id,
    generalization_target = generalization_target,
    target_derived = target_derived,
    post_outcome = post_outcome
  )
}


check_status <- function(audit, check_id) {
  audit$checks$status[
    match(check_id, audit$checks$check_id)
  ]
}


test_that("clean new-participant partitions pass", {
  partitions <- make_leakage_partitions()
  audit <- run_leakage_audit(partitions)

  expect_s3_class(
    audit,
    "gazepoint_ml_leakage_audit"
  )
  expect_identical(audit$status, "pass")
  expect_identical(nrow(audit$issues), 0L)
  expect_identical(
    check_status(
      audit,
      "participant_partition_compatibility"
    ),
    "pass"
  )
  expect_identical(
    check_status(audit, "trial_partition_overlap"),
    "pass"
  )
})


test_that("participant overlap fails new-participant evaluation", {
  partitions <- make_leakage_partitions()
  partitions$assessment$participant_id[1] <- "P01"

  audit <- run_leakage_audit(partitions)

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(
      audit,
      "participant_partition_compatibility"
    ),
    "fail"
  )
})


test_that("known-participant new-trial evaluation is supported", {
  partitions <- make_leakage_partitions()
  partitions$assessment$participant_id <- c(
    "P01",
    "P02",
    "P01",
    "P02"
  )

  audit <- run_leakage_audit(
    partitions,
    generalization_target =
      "new_trials_known_participants"
  )

  expect_identical(audit$status, "pass")
  expect_identical(
    check_status(
      audit,
      "participant_partition_compatibility"
    ),
    "pass"
  )
})


test_that("unseen participants fail a known-participant target", {
  partitions <- make_leakage_partitions()
  partitions$assessment$participant_id <- c(
    "P01",
    "P02",
    "P05",
    "P02"
  )

  audit <- run_leakage_audit(
    partitions,
    generalization_target =
      "new_trials_known_participants"
  )

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(
      audit,
      "participant_partition_compatibility"
    ),
    "fail"
  )
})


test_that("stimulus overlap fails unseen-stimulus evaluation", {
  partitions <- make_leakage_partitions()
  partitions$assessment$participant_id <- c(
    "P01",
    "P02",
    "P01",
    "P02"
  )
  partitions$assessment$stimulus_id[1] <- "S01"

  audit <- run_leakage_audit(
    partitions,
    generalization_target = "new_stimuli"
  )

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(
      audit,
      "stimulus_partition_compatibility"
    ),
    "fail"
  )
})


test_that("participant-trial overlap fails new-trial evaluation", {
  partitions <- make_leakage_partitions()

  partitions$assessment$participant_id <- c(
    "P01",
    "P02",
    "P01",
    "P02"
  )

  partitions$assessment$trial_id[1] <- "T01"

  audit <- run_leakage_audit(
    partitions,
    generalization_target =
      "new_trials_known_participants"
  )

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(audit, "trial_partition_overlap"),
    "fail"
  )
})


test_that("trial labels may repeat across different participants", {
  partitions <- make_leakage_partitions()

  partitions$analysis$trial_id <- c(
    "T01",
    "T02",
    "T01",
    "T02"
  )

  partitions$assessment$trial_id <- c(
    "T01",
    "T02",
    "T01",
    "T02"
  )

  audit <- run_leakage_audit(
    partitions,
    generalization_target = "new_participants"
  )

  expect_identical(audit$status, "pass")
  expect_identical(
    check_status(audit, "trial_partition_overlap"),
    "pass"
  )
})


test_that("exact row overlap is detected", {
  partitions <- make_leakage_partitions()
  partitions$assessment[1, ] <- partitions$analysis[1, ]

  audit <- run_leakage_audit(partitions)

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(audit, "exact_row_overlap"),
    "fail"
  )
})


test_that("duplicated rows inside a partition require review", {
  partitions <- make_leakage_partitions()

  partitions$analysis <- rbind(
    partitions$analysis,
    partitions$analysis[1, , drop = FALSE]
  )

  audit <- run_leakage_audit(partitions)

  expect_identical(audit$status, "review")
  expect_identical(
    check_status(
      audit,
      "duplicate_rows_within_partitions"
    ),
    "review"
  )
})


test_that("outcome and prohibited predictor roles fail", {
  partitions <- make_leakage_partitions()

  partitions$analysis$target_proxy <- c(1, 0, 1, 0)
  partitions$assessment$target_proxy <- c(0, 1, 0, 1)

  partitions$analysis$post_metric <- c(4, 3, 2, 1)
  partitions$assessment$post_metric <- c(8, 7, 6, 5)

  audit <- run_leakage_audit(
    partitions,
    predictors = c(
      "outcome",
      "participant_id",
      "feature_a",
      "target_proxy",
      "post_metric"
    ),
    target_derived = "target_proxy",
    post_outcome = "post_metric"
  )

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(audit, "outcome_in_predictors"),
    "fail"
  )
  expect_identical(
    check_status(
      audit,
      "declared_identifier_in_predictors"
    ),
    "fail"
  )
  expect_identical(
    check_status(audit, "target_derived_predictors"),
    "fail"
  )
  expect_identical(
    check_status(audit, "post_outcome_predictors"),
    "fail"
  )
})


test_that("missing required grouping roles fail", {
  partitions <- make_leakage_partitions()

  audit <- run_leakage_audit(
    partitions,
    participant_id = NULL
  )

  expect_identical(audit$status, "fail")
  expect_identical(
    check_status(audit, "participant_id_available"),
    "fail"
  )
})


test_that("identifier-like predictor names require review", {
  partitions <- make_leakage_partitions()

  partitions$analysis$record_index <- seq_len(
    nrow(partitions$analysis)
  )
  partitions$assessment$record_index <- 5:8

  audit <- run_leakage_audit(
    partitions,
    predictors = c(
      "feature_a",
      "feature_b",
      "record_index"
    )
  )

  expect_identical(audit$status, "review")
  expect_identical(
    check_status(
      audit,
      "identifier_like_predictor_names"
    ),
    "review"
  )
})


test_that("invalid partition structures are rejected", {
  partitions <- make_leakage_partitions()

  mismatched <- partitions
  mismatched$assessment$extra_column <- 1

  expect_error(
    run_leakage_audit(mismatched),
    "same column names",
    fixed = TRUE
  )

  expect_error(
    run_leakage_audit(
      partitions,
      predictors = "missing_predictor"
    ),
    "Declared columns not found",
    fixed = TRUE
  )

  empty_partitions <- partitions
  empty_partitions$analysis <- partitions$analysis[0, ]

  expect_error(
    run_leakage_audit(empty_partitions),
    "at least one row",
    fixed = TRUE
  )
})


test_that("print method reports the audit status", {
  partitions <- make_leakage_partitions()
  audit <- run_leakage_audit(partitions)

  output <- capture.output(print(audit))

  expect_true(
    any(grepl("Overall status: PASS", output, fixed = TRUE))
  )
  expect_true(
    any(grepl("Non-passing checks: 0", output, fixed = TRUE))
  )
})

test_that("audit tables can be written to CSV", {
  partitions <- make_leakage_partitions()
  partitions$assessment$participant_id[1] <- "P01"

  audit <- run_leakage_audit(partitions)

  output <- tempfile(fileext = ".csv")
  on.exit(unlink(output), add = TRUE)

  result <- write_gazepoint_ml_leakage_audit_csv(
    audit,
    output,
    table = "issues"
  )

  exported <- utils::read.csv(
    output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_true(file.exists(output))
  expect_identical(
    result,
    normalizePath(
      output,
      winslash = "/",
      mustWork = TRUE
    )
  )
  expect_identical(
    names(exported),
    names(audit$issues)
  )
  expect_identical(
    nrow(exported),
    nrow(audit$issues)
  )

  expect_error(
    write_gazepoint_ml_leakage_audit_csv(
      audit,
      output
    ),
    "Output file already exists",
    fixed = TRUE
  )

  expect_silent(
    write_gazepoint_ml_leakage_audit_csv(
      audit,
      output,
      table = "checks",
      overwrite = TRUE
    )
  )
})


test_that("audit CSV writer validates its inputs", {
  partitions <- make_leakage_partitions()
  audit <- run_leakage_audit(partitions)

  expect_error(
    write_gazepoint_ml_leakage_audit_csv(
      data.frame(),
      tempfile(fileext = ".csv")
    ),
    "must inherit",
    fixed = TRUE
  )

  expect_error(
    write_gazepoint_ml_leakage_audit_csv(
      audit,
      tempfile(fileext = ".txt")
    ),
    ".csv extension",
    fixed = TRUE
  )

  missing_directory <- file.path(
    tempdir(),
    "directory-that-does-not-exist",
    "audit.csv"
  )

  expect_error(
    write_gazepoint_ml_leakage_audit_csv(
      audit,
      missing_directory
    ),
    "Output directory does not exist",
    fixed = TRUE
  )
})
