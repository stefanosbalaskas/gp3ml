test_that("internal data cannot be silently labelled external validation", {
  fixture <- roadmap_fixture(seed = 1601L, repeats = 1L)
  model <- fit_gazepoint_model(
    fixture$data,
    fixture$task,
    fixture$predictors,
    "glm",
    seed = 1601L
  )
  report <- evaluate_gazepoint_external_transportability(
    model,
    development_data = fixture$data,
    external_data = NULL
  )
  expect_s3_class(report, "gp3ml_transportability_report")
  expect_identical(report$status, "not_externally_validated")
  expect_match(report$limitations, "Internal holdout")
})

test_that("independent external data produce schema and transportability tables", {
  fixture <- roadmap_fixture(seed = 1602L, repeats = 1L)
  development_evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds,
    fixture$task,
    fixture$predictors,
    "glm",
    seed = 1602L,
    assess_calibration = TRUE,
    calibration_bootstrap = 0L
  )
  model <- fit_gazepoint_model(
    fixture$data,
    fixture$task,
    fixture$predictors,
    "glm",
    seed = 1602L
  )
  external <- simulate_gazepoint_governed_data(10L, 6L, 1L, 1603L)
  external$participant_id <- paste0("E", external$participant_id)
  external$trial_id <- paste0("E", external$trial_id)
  external$stimulus_id <- paste0("E", external$stimulus_id)
  declaration <- declare_gazepoint_external_dataset(
    external,
    "synthetic_external",
    independent = TRUE,
    origin = "Independent deterministic synthetic generation"
  )
  report <- evaluate_gazepoint_external_transportability(
    model,
    development_data = fixture$data,
    external_data = external,
    declaration = declaration,
    development_evaluation = development_evaluation,
    bootstrap = 0L,
    seed = 1603L
  )
  expect_identical(report$status, "externally_validated")
  expect_true(nrow(report$schema) > 0L)
  expect_equal(nrow(report$group_coverage), 2L)
  expect_true(all(report$group_coverage$overlapping_groups == 0L))
  expect_s3_class(report$validation_summary, "gp3ml_transportability_validation")
})

test_that("declared non-independent data remain not externally validated", {
  fixture <- roadmap_fixture(seed = 1604L, repeats = 1L)
  model <- fit_gazepoint_model(
    fixture$data, fixture$task, fixture$predictors, "glm", seed = 1604L
  )
  declaration <- declare_gazepoint_external_dataset(
    fixture$data,
    "internal_reuse",
    independent = FALSE,
    origin = "Development sample"
  )
  report <- evaluate_gazepoint_external_transportability(
    model,
    fixture$data,
    fixture$data,
    declaration,
    bootstrap = 0L
  )
  expect_identical(report$status, "not_externally_validated")
})

test_that("external declarations are fingerprinted and outcomes are required", {
  fixture <- roadmap_fixture(seed = 1605L, repeats = 1L)
  model <- fit_gazepoint_model(
    fixture$data, fixture$task, fixture$predictors, "glm", seed = 1605L
  )
  external <- simulate_gazepoint_governed_data(8L, 4L, 1L, 1606L)
  external$participant_id <- paste0("E", external$participant_id)
  external$trial_id <- paste0("E", external$trial_id)
  external$stimulus_id <- paste0("E", external$stimulus_id)
  declaration <- declare_gazepoint_external_dataset(
    external,
    "fingerprinted_external",
    independent = TRUE,
    origin = "Independent deterministic synthetic generation"
  )
  altered <- external
  altered$tracking_ratio[[1L]] <- altered$tracking_ratio[[1L]] - 0.01
  mismatch <- evaluate_gazepoint_external_transportability(
    model,
    fixture$data,
    altered,
    declaration,
    bootstrap = 0L
  )
  expect_identical(mismatch$status, "external_declaration_mismatch")
  expect_false(mismatch$declaration_hash_matches)

  missing_outcome <- external[names(external) != fixture$task$outcome]
  missing_declaration <- declare_gazepoint_external_dataset(
    missing_outcome,
    "missing_outcome_external",
    independent = TRUE,
    origin = "Independent deterministic synthetic generation"
  )
  incompatible <- evaluate_gazepoint_external_transportability(
    model,
    fixture$data,
    missing_outcome,
    missing_declaration,
    bootstrap = 0L
  )
  expect_identical(incompatible$status, "incompatible_external_schema")
  expect_match(incompatible$reason, "Missing outcome")
})
