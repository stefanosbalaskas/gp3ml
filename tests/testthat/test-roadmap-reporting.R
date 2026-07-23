test_that("release model card records selection uncertainty and transportability", {
  fixture <- roadmap_fixture(seed = 1701L, n_participants = 15L, repeats = 1L)
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds, fixture$task, fixture$predictors, "glm", seed = 1701L
  )
  grid <- create_gazepoint_tuning_grid(
    "glm",
    thresholds = c(0.45, 0.55),
    complexity = c(1, 2),
    interpretability = "high"
  )
  tuned <- tune_gazepoint_model(
    fixture$folds, fixture$task, grid, fixture$predictors, seed = 1701L
  )
  selection <- select_gazepoint_model(
    tuned,
    "brier",
    "minimize",
    rationale = "Predeclared calibration-sensitive primary metric."
  )
  model <- fit_gazepoint_model(
    fixture$data, fixture$task, fixture$predictors, "glm", seed = 1701L
  )
  uncertainty <- summarize_gazepoint_resample_uncertainty(evaluation)
  transportability <- evaluate_gazepoint_external_transportability(
    model,
    fixture$data,
    external_data = NULL
  )
  card <- create_gazepoint_release_model_card(
    model,
    intended_use = "Support manual review of predefined recording-quality status.",
    evaluation = evaluation,
    selection = selection,
    uncertainty = uncertainty,
    feature_manifest = fixture$manifest,
    transportability = transportability,
    limitations = c(
      "Synthetic demonstration only.",
      "No claim beyond the declared generalization target."
    )
  )
  expect_s3_class(card, "gp3ml_release_model_card")
  expect_true(card$selection_procedure_recorded)
  expect_identical(card$uncertainty_unit, "fold")
  expect_identical(card$external_validation_status, "not_externally_validated")
  output <- tempfile(fileext = ".md")
  write_gazepoint_release_model_card(card, output)
  text <- paste(readLines(output, warn = FALSE), collapse = "\n")
  expect_match(text, "Model-selection procedure")
  expect_match(text, "Target-aligned uncertainty")
  expect_match(text, "not_externally_validated")
  unlink(output)
})
