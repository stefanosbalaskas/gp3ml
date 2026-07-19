make_clean_feature_manifest <- function() {
  create_gazepoint_feature_manifest(
    features = c(
      "fixation_duration",
      "pupil_change"
    ),
    scientific_source = c(
      "Gazepoint fixation export",
      "Gazepoint all-gaze export"
    ),
    source_table = c(
      "fixations",
      "all_gaze"
    ),
    transformation = c(
      "Trial-level mean",
      "Baseline-adjusted change"
    ),
    availability_stage = "during_exposure",
    prediction_time_available = TRUE,
    outcome_derived = FALSE,
    post_outcome = FALSE,
    identifier = FALSE,
    preprocessing_scope = c(
      "none",
      "resampling_fold"
    ),
    fold_local_required = c(
      FALSE,
      TRUE
    ),
    reviewer_notes = ""
  )
}


manifest_check_status <- function(
    validation,
    feature,
    check_id) {
  index <- validation$checks$feature == feature &
    validation$checks$check_id == check_id

  validation$checks$status[index]
}


test_that("feature manifests recycle scalar metadata", {
  manifest <- make_clean_feature_manifest()

  expect_s3_class(
    manifest,
    "gazepoint_feature_manifest"
  )
  expect_identical(nrow(manifest), 2L)
  expect_identical(
    manifest$availability_stage,
    rep("during_exposure", 2L)
  )
  expect_identical(
    manifest$prediction_time_available,
    rep(TRUE, 2L)
  )
})


test_that("complete safe manifests pass validation", {
  manifest <- make_clean_feature_manifest()
  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_s3_class(
    validation,
    "gazepoint_feature_manifest_validation"
  )
  expect_identical(validation$status, "pass")
  expect_identical(validation$n_features, 2L)
  expect_identical(nrow(validation$issues), 0L)
})


test_that("incomplete default manifests require review", {
  manifest <- create_gazepoint_feature_manifest(
    features = "fixation_duration"
  )

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_identical(validation$status, "review")
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "provenance_metadata_complete"
    ),
    "review"
  )
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "prediction_time_available"
    ),
    "review"
  )
})


test_that("outcome-derived features fail validation", {
  manifest <- make_clean_feature_manifest()
  manifest$outcome_derived[1] <- TRUE

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_identical(validation$status, "fail")
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "outcome_derived"
    ),
    "fail"
  )
})


test_that("post-outcome features fail validation", {
  manifest <- make_clean_feature_manifest()

  manifest$post_outcome[1] <- TRUE
  manifest$availability_stage[1] <- "post_outcome"
  manifest$prediction_time_available[1] <- FALSE

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_identical(validation$status, "fail")
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "post_outcome"
    ),
    "fail"
  )
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "prediction_time_available"
    ),
    "fail"
  )
})


test_that("identifier features fail validation", {
  manifest <- make_clean_feature_manifest()
  manifest$identifier[1] <- TRUE

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_identical(validation$status, "fail")
  expect_identical(
    manifest_check_status(
      validation,
      "fixation_duration",
      "identifier"
    ),
    "fail"
  )
})


test_that("global preprocessing fails when fold-local estimation is required", {
  manifest <- make_clean_feature_manifest()

  manifest$preprocessing_scope[2] <- "global"
  manifest$fold_local_required[2] <- TRUE

  validation <- validate_gazepoint_feature_manifest(
    manifest
  )

  expect_identical(validation$status, "fail")
  expect_identical(
    manifest_check_status(
      validation,
      "pupil_change",
      "preprocessing_scope_compatible"
    ),
    "fail"
  )
})


test_that("invalid manifest inputs are rejected", {
  expect_error(
    create_gazepoint_feature_manifest(
      features = c("feature_a", "feature_a")
    ),
    "unique",
    fixed = TRUE
  )

  expect_error(
    create_gazepoint_feature_manifest(
      features = "feature_a",
      availability_stage = "after_everything"
    ),
    "availability_stage",
    fixed = TRUE
  )

  expect_error(
    create_gazepoint_feature_manifest(
      features = "feature_a",
      preprocessing_scope = "whole_dataset"
    ),
    "preprocessing_scope",
    fixed = TRUE
  )

  incomplete <- data.frame(
    feature = "feature_a",
    stringsAsFactors = FALSE
  )

  expect_error(
    validate_gazepoint_feature_manifest(
      incomplete
    ),
    "missing required columns",
    fixed = TRUE
  )
})


test_that("validation print method reports status", {
  validation <- validate_gazepoint_feature_manifest(
    make_clean_feature_manifest()
  )

  output <- capture.output(print(validation))

  expect_true(
    any(
      grepl(
        "Overall status: PASS",
        output,
        fixed = TRUE
      )
    )
  )

  expect_true(
    any(
      grepl(
        "Features: 2",
        output,
        fixed = TRUE
      )
    )
  )
})


test_that("feature manifests can be written to CSV", {
  manifest <- make_clean_feature_manifest()

  output <- tempfile(fileext = ".csv")
  on.exit(unlink(output), add = TRUE)

  result <- write_gazepoint_feature_manifest_csv(
    manifest,
    output
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
    names(manifest)
  )
  expect_identical(
    nrow(exported),
    nrow(manifest)
  )

  expect_error(
    write_gazepoint_feature_manifest_csv(
      manifest,
      output
    ),
    "already exists",
    fixed = TRUE
  )
})


test_that("validation tables can be written to CSV", {
  validation <- validate_gazepoint_feature_manifest(
    create_gazepoint_feature_manifest(
      features = "feature_a"
    )
  )

  output <- tempfile(fileext = ".csv")
  on.exit(unlink(output), add = TRUE)

  expect_silent(
    write_gazepoint_feature_manifest_csv(
      validation,
      output,
      table = "issues"
    )
  )

  exported <- utils::read.csv(
    output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_identical(
    names(exported),
    names(validation$issues)
  )
  expect_identical(
    nrow(exported),
    nrow(validation$issues)
  )
})


test_that("CSV writer validates requested tables", {
  manifest <- make_clean_feature_manifest()

  expect_error(
    write_gazepoint_feature_manifest_csv(
      manifest,
      tempfile(fileext = ".csv"),
      table = "issues"
    ),
    "Plain manifest inputs",
    fixed = TRUE
  )

  expect_error(
    write_gazepoint_feature_manifest_csv(
      manifest,
      tempfile(fileext = ".txt")
    ),
    ".csv extension",
    fixed = TRUE
  )
})
