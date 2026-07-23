test_that("nested folds isolate every outer assessment partition", {
  fixture <- roadmap_fixture(seed = 1401L, n_participants = 18L)
  nested <- create_gazepoint_nested_folds(
    fixture$folds,
    inner_v = 2L,
    inner_repeats = 1L,
    seed = 1401L
  )
  expect_s3_class(nested, "gp3ml_nested_folds")
  expect_identical(nested$audit$status, "pass")
  expect_true(all(nested$audit$checks$outer_assessment_overlap == 0L))
  expect_true(all(nested$audit$checks$inner_analysis_assessment_overlap == 0L))
})

test_that("nested evaluation records inner selection and outer predictions", {
  fixture <- roadmap_fixture(seed = 1402L, n_participants = 18L)
  nested <- create_gazepoint_nested_folds(
    fixture$folds,
    inner_v = 2L,
    inner_repeats = 1L,
    seed = 1402L
  )
  grid <- create_gazepoint_tuning_grid(
    "glm",
    thresholds = c(0.45, 0.55),
    complexity = c(1, 2),
    interpretability = "high"
  )
  evaluation <- evaluate_gazepoint_nested_resampling(
    nested,
    fixture$task,
    grid,
    selection_metric = "brier",
    direction = "minimize",
    predictors = fixture$predictors,
    minimum_success_prop = 0.5,
    seed = 1402L
  )
  expect_s3_class(evaluation, "gp3ml_nested_evaluation")
  expect_true(all(evaluation$predictions$stage == "outer_assessment"))
  expect_true(all(evaluation$fold_status$selected_candidate %in% grid$candidates$candidate_id))
  expect_s3_class(evaluation$validation, "gp3ml_nested_evaluation_validation")
})

test_that("nested audit detects deliberate outer-assessment contamination", {
  fixture <- roadmap_fixture(seed = 1403L, n_participants = 18L, repeats = 1L)
  nested <- create_gazepoint_nested_folds(
    fixture$folds,
    inner_v = 2L,
    inner_repeats = 1L,
    seed = 1403L
  )
  source_row_id <- nested$outer_metadata$source_row_id
  outer_row <- nested$folds[[1L]]$outer$assessment[[source_row_id]][[1L]]
  nested$folds[[1L]]$inner$folds[[1L]]$analysis[[source_row_id]][[1L]] <- outer_row
  audit <- audit_gazepoint_nested_resampling(nested)
  expect_identical(audit$status, "fail")
  expect_true(any(audit$checks$outer_assessment_overlap > 0L))
})
