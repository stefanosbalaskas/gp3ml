test_that("explicit tuning retains every candidate and creates no winner", {
  fixture <- roadmap_fixture(seed = 1301L, n_participants = 15L)
  grid <- create_gazepoint_tuning_grid(
    engine = "glm",
    preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
    thresholds = c(0.45, 0.55),
    complexity = "low",
    interpretability = "high"
  )
  expect_s3_class(grid, "gp3ml_tuning_grid")
  expect_equal(nrow(grid$candidates), 4L)
  tuned <- tune_gazepoint_model(
    fixture$folds,
    fixture$task,
    grid,
    predictors = fixture$predictors,
    seed = 1301L
  )
  expect_s3_class(tuned, "gp3ml_model_tuning")
  expect_equal(length(tuned$results), 4L)
  expect_null(tuned$selection)
  expect_setequal(unique(tuned$comparison$candidate_id), grid$candidates$candidate_id)
})

test_that("selection requires a governed metric and rationale", {
  fixture <- roadmap_fixture(seed = 1302L, n_participants = 15L)
  grid <- create_gazepoint_tuning_grid(
    "glm",
    thresholds = c(0.4, 0.5),
    complexity = c(1, 2),
    interpretability = "high"
  )
  tuned <- tune_gazepoint_model(
    fixture$folds, fixture$task, grid, fixture$predictors, seed = 1302L
  )
  expect_error(
    select_gazepoint_model(
      tuned,
      metric = "accuracy",
      direction = "maximize",
      rationale = "Not acceptable"
    ),
    "cannot be the primary"
  )
  selection <- select_gazepoint_model(
    tuned,
    metric = "brier",
    direction = "minimize",
    rationale = "Predeclared calibration-sensitive metric with explicit human review."
  )
  expect_s3_class(selection, "gp3ml_model_selection")
  expect_false(selection$autonomous_selection)
  expect_false(selection$refit_performed)
  expect_true(selection$candidate_id %in% grid$candidates$candidate_id)
})

test_that("failed tuning candidates remain in the comparison", {
  fixture <- roadmap_fixture(seed = 1303L, n_participants = 15L, repeats = 1L)
  grid <- create_gazepoint_tuning_grid(
    engine = c("glm", "deliberately_unknown_engine"),
    thresholds = 0.5,
    complexity = c(1, 2),
    interpretability = c("high", "unknown")
  )
  tuned <- tune_gazepoint_model(
    fixture$folds,
    fixture$task,
    grid,
    fixture$predictors,
    seed = 1303L,
    continue_on_error = TRUE
  )
  expect_equal(length(tuned$results), 2L)
  expect_true(any(vapply(tuned$results, function(x) x$status == "fail", logical(1))))
  failed <- tuned$comparison[tuned$comparison$candidate_status == "fail", , drop = FALSE]
  expect_equal(nrow(failed), 1L)
  expect_match(failed$error, "Unknown engine")
})
