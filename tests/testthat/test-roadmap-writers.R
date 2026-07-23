test_that("roadmap objects export auditable tables and reports", {
  fixture <- roadmap_fixture(
    seed = 1801L,
    n_participants = 18L,
    n_stimuli = 4L,
    trials_per_cell = 1L,
    repeats = 1L
  )
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds,
    fixture$task,
    fixture$predictors,
    "glm",
    seed = 1801L
  )
  output <- tempfile("gp3ml-roadmap-writers-")
  dir.create(output)
  evaluation_paths <- write_gazepoint_resample_evaluation(
    evaluation,
    output,
    overwrite = TRUE
  )
  expect_true(all(file.exists(evaluation_paths)))

  grid <- create_gazepoint_tuning_grid(
    "glm",
    thresholds = c(0.45, 0.55),
    complexity = c(1, 2),
    interpretability = "high"
  )
  tuning <- tune_gazepoint_model(
    fixture$folds,
    fixture$task,
    grid,
    fixture$predictors,
    seed = 1801L
  )
  selection <- select_gazepoint_model(
    tuning,
    metric = "brier",
    direction = "minimize",
    minimum_success_prop = 0.5,
    rationale = "Predeclared writer-test selection rule."
  )
  tuning_paths <- write_gazepoint_model_tuning(
    tuning,
    output,
    selection = selection,
    overwrite = TRUE
  )
  expect_true(all(file.exists(tuning_paths)))

  predictions <- evaluation$predictions
  uncertainty <- bootstrap_gazepoint_metrics_by_unit(
    fixture$task,
    truth = predictions$truth,
    prediction = factor(
      predictions$prediction,
      levels = levels(fixture$data$quality_status)
    ),
    probability = predictions$probability,
    participant_id = predictions$participant_id,
    unit = "participant",
    bootstrap = 10L,
    seed = 1801L
  )
  uncertainty_paths <- write_gazepoint_target_uncertainty(
    uncertainty,
    output,
    overwrite = TRUE
  )
  expect_true(all(file.exists(uncertainty_paths)))

  model <- fit_gazepoint_model(
    fixture$data,
    fixture$task,
    fixture$predictors,
    "glm",
    seed = 1801L
  )
  transportability <- evaluate_gazepoint_external_transportability(
    model,
    fixture$data,
    external_data = NULL
  )
  transportability_path <- file.path(output, "transportability.md")
  write_gazepoint_transportability_report(
    transportability,
    transportability_path
  )
  expect_true(file.exists(transportability_path))

  nested <- create_gazepoint_nested_folds(
    fixture$folds,
    inner_v = 2L,
    inner_repeats = 1L,
    seed = 1801L
  )
  nested_evaluation <- evaluate_gazepoint_nested_resampling(
    nested,
    fixture$task,
    grid,
    selection_metric = "brier",
    direction = "minimize",
    predictors = fixture$predictors,
    minimum_success_prop = 0.5,
    seed = 1801L
  )
  nested_paths <- write_gazepoint_nested_evaluation(
    nested_evaluation,
    output,
    overwrite = TRUE
  )
  expect_true(all(file.exists(nested_paths)))

  unlink(output, recursive = TRUE, force = TRUE)
})
