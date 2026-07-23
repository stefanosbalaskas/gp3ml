test_that("grouped evaluation fits and predicts within every materialized fold", {
  fixture <- roadmap_fixture(seed = 1201L)
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds,
    fixture$task,
    predictors = fixture$predictors,
    engine = "glm",
    seed = 1201L,
    keep_models = TRUE
  )
  expect_s3_class(evaluation, "gp3ml_resample_evaluation")
  expect_equal(nrow(evaluation$fold_status), fixture$folds$metadata$n_folds_total)
  expect_true(all(evaluation$predictions$stage == "assessment"))
  expect_true(all(evaluation$predictions$fold_id %in% names(fixture$folds$folds)))
  expect_true(all(c("roc_auc", "balanced_accuracy", "brier", "log_loss") %in% evaluation$metrics$metric))
  expect_s3_class(evaluation$validation, "gp3ml_resample_evaluation_validation")
  expect_false(any(vapply(evaluation$fold_results, function(z) {
    if (is.null(z$model)) return(FALSE)
    identical(z$analysis_hash, z$assessment_hash)
  }, logical(1))))
})

test_that("fold failures remain explicit", {
  fixture <- roadmap_fixture(seed = 1202L)
  bad_engine <- integrate_black_box_model(
    name = "deliberate_failure",
    fit_fun = function(x, y, task, args) stop("deliberate fold failure"),
    predict_fun = function(fit, newdata, type, task, ...) numeric(nrow(newdata)),
    supports = "classification",
    probability = TRUE,
    safety_declaration = list(
      prohibited_uses_acknowledged = TRUE,
      prediction_time_inputs_only = TRUE,
      group_aware_evaluation_required = TRUE
    )
  )
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds,
    fixture$task,
    predictors = fixture$predictors,
    engine = bad_engine,
    seed = 1202L,
    continue_on_error = TRUE
  )
  expect_true(all(evaluation$fold_status$status == "fail"))
  expect_true(all(grepl("deliberate fold failure", evaluation$fold_status$error, fixed = TRUE)))
  expect_equal(nrow(evaluation$predictions), 0L)
})

test_that("performance summaries preserve the declared target", {
  fixture <- roadmap_fixture(seed = 1203L)
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds, fixture$task, fixture$predictors, "glm", seed = 1203L
  )
  fold_summary <- summarize_gazepoint_resample_performance(evaluation)
  pooled <- summarize_gazepoint_resample_performance(evaluation, "pooled_rows")
  expect_s3_class(fold_summary, "gp3ml_resample_performance_summary")
  expect_identical(fold_summary$generalization_target, "new_participants")
  expect_true("aggregation_warning" %in% names(pooled$summary))
})

test_that("all declared grouping targets run through materialized folds", {
  specifications <- list(
    new_trials_known_participants = list(n_participants = 12L, n_stimuli = 4L, trials = 2L, v = 2L),
    new_participants = list(n_participants = 12L, n_stimuli = 4L, trials = 1L, v = 2L),
    new_stimuli = list(n_participants = 12L, n_stimuli = 6L, trials = 1L, v = 3L),
    new_participants_and_new_stimuli = list(n_participants = 12L, n_stimuli = 6L, trials = 1L, v = 2L)
  )
  for (i in seq_along(specifications)) {
    target <- names(specifications)[[i]]
    spec <- specifications[[i]]
    data <- simulate_gazepoint_governed_data(
      spec$n_participants,
      spec$n_stimuli,
      spec$trials,
      seed = 1250L + i
    )
    predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
    task <- create_gazepoint_synthetic_task(data, "recording_quality", target)
    manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
    folds <- create_gazepoint_group_folds(
      data,
      task$outcome,
      predictors,
      manifest,
      target,
      "participant_id",
      "trial_id",
      "stimulus_id",
      v = spec$v,
      repeats = 1L,
      seed = 1250L + i
    )
    evaluation <- evaluate_gazepoint_group_folds(
      folds,
      task,
      predictors,
      "glm",
      seed = 1250L + i,
      continue_on_error = TRUE
    )
    expect_identical(evaluation$generalization_target, target)
    expect_equal(nrow(evaluation$fold_status), folds$metadata$n_folds_total)
    expect_true(all(evaluation$predictions$stage == "assessment"))
  }
})
