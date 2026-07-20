make_modeling_core_data <- function(seed = 20260721L) {
  set.seed(seed)
  n_participants <- 30L
  trials_per_participant <- 4L
  n <- n_participants * trials_per_participant

  data <- data.frame(
    participant_id = rep(sprintf("P%02d", seq_len(n_participants)), each = trials_per_participant),
    trial_id = sprintf("T%03d", seq_len(n)),
    stimulus_id = rep(sprintf("S%02d", seq_len(trials_per_participant)), times = n_participants),
    valid_gaze_prop = runif(n, 0.45, 0.99),
    fixation_count = rpois(n, 14),
    mean_pupil = rnorm(n, 3.2, 0.4),
    stringsAsFactors = FALSE
  )

  eta <- -1.2 +
    2.4 * data$valid_gaze_prop +
    0.035 * data$fixation_count -
    0.20 * data$mean_pupil +
    rnorm(n, 0, 0.65)

  data$quality_status <- factor(
    ifelse(runif(n) < stats::plogis(eta), "review", "pass"),
    levels = c("pass", "review")
  )

  data
}

make_modeling_core_task <- function(data) {
  declare_gazepoint_task(
    data = data,
    outcome = "quality_status",
    purpose = paste(
      "Predict a predefined recording-quality review status",
      "to support manual quality-control assessment"
    ),
    task_type = "classification",
    unit_id = "trial_id",
    participant_id = "participant_id",
    stimulus_id = "stimulus_id",
    generalization_target = "new_participants",
    positive = "review"
  )
}

test_that("governed task declarations block prohibited inference", {
  data <- make_modeling_core_data()
  data$emotion <- factor(rep(c("low", "high"), length.out = nrow(data)))

  expect_error(
    declare_gazepoint_task(
      data = data,
      outcome = "emotion",
      purpose = "Infer participant emotion from gaze measurements",
      task_type = "classification",
      unit_id = "trial_id",
      participant_id = "participant_id",
      stimulus_id = "stimulus_id",
      generalization_target = "new_participants",
      positive = "high"
    ),
    "prohibited"
  )
})

test_that("safe tasks and role validation are structured", {
  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")

  validation <- validate_gazepoint_ml_roles(
    data = data,
    task = task,
    predictors = predictors
  )

  expect_s3_class(task, "gp3ml_task")
  expect_s3_class(validation, "gp3ml_role_validation")
  expect_true(validation$status %in% c("pass", "review"))
  expect_equal(validation$checks$status[validation$checks$check == "feature_manifest"], "review")
})

test_that("fold-local preprocessing fits and bakes deterministic matrices", {
  data <- make_modeling_core_data()
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")

  preprocessor <- fit_gazepoint_preprocessor(
    data = data,
    predictors = predictors,
    center = TRUE,
    scale = TRUE
  )

  baked_a <- bake_gazepoint_preprocessor(preprocessor, data)
  baked_b <- bake_gazepoint_preprocessor(preprocessor, data)

  expect_s3_class(preprocessor, "gp3ml_preprocessor")
  expect_true(is.matrix(baked_a))
  expect_identical(baked_a, baked_b)
  expect_equal(nrow(baked_a), nrow(data))
})

test_that("GLM classifier fits and returns governed predictions", {
  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")

  model <- train_gazepoint_classifier(
    data = data,
    task = task,
    predictors = predictors,
    engine = "glm",
    seed = 20260721L
  )

  probability <- predict(model, data, type = "probability")
  prediction <- predict(model, data, type = "class")

  expect_s3_class(model, "gp3ml_model")
  expect_length(probability, nrow(data))
  expect_length(prediction, nrow(data))
  expect_true(all(is.finite(probability)))
  expect_true(all(probability >= 0 & probability <= 1))
})

test_that("classification metrics, uncertainty, and calibration are available", {
  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")
  model <- train_gazepoint_classifier(data, task, predictors, "glm", seed = 20260721L)
  probability <- predict(model, data, type = "probability")
  prediction <- predict(model, data, type = "class")

  metrics <- gazepoint_classification_metrics(
    truth = data$quality_status,
    probability = probability,
    predicted = prediction,
    positive = "review"
  )

  uncertainty <- bootstrap_gazepoint_metrics(
    task = task,
    truth = data$quality_status,
    prediction = prediction,
    probability = probability,
    bootstrap = 20L,
    seed = 20260721L
  )

  calibration <- assess_gazepoint_calibration(
    truth = data$quality_status,
    probability = probability,
    positive = "review",
    bins = 5L,
    bootstrap = 20L,
    seed = 20260721L
  )

  expect_true(is.data.frame(metrics))
  expect_s3_class(uncertainty, "gp3ml_metric_uncertainty")
  expect_s3_class(calibration, "gp3ml_calibration_assessment")
  expect_equal(nrow(uncertainty$draws), 20L)
  expect_equal(nrow(calibration$summary), 1L)
})

test_that("model cards and reproducibility reports export", {
  skip_if_not_installed("jsonlite")

  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")
  model <- train_gazepoint_classifier(data, task, predictors, "glm", seed = 20260721L)
  probability <- predict(model, data, type = "probability")
  prediction <- predict(model, data, type = "class")
  uncertainty <- bootstrap_gazepoint_metrics(
    task, data$quality_status, prediction, probability,
    bootstrap = 10L, seed = 20260721L
  )
  calibration <- assess_gazepoint_calibration(
    data$quality_status, probability, "review",
    bins = 4L, bootstrap = 10L, seed = 20260721L
  )

  card <- create_gazepoint_model_card(
    model = model,
    intended_use = "Manual recording-quality review support.",
    evaluation = uncertainty,
    calibration = calibration,
    limitations = "Synthetic regression test."
  )

  report <- create_gazepoint_reproducibility_report(
    objects = list(task = task, model = model, card = card),
    data = data,
    seeds = list(model = 20260721L),
    project_path = tempdir()
  )

  markdown_path <- tempfile(fileext = ".md")
  json_path <- tempfile(fileext = ".json")
  reproducibility_path <- tempfile(fileext = ".md")

  write_gazepoint_model_card(card, markdown_path, "markdown")
  write_gazepoint_model_card(card, json_path, "json")
  write_gazepoint_reproducibility_report(report, reproducibility_path)

  parsed <- jsonlite::read_json(json_path, simplifyVector = TRUE)

  expect_s3_class(card, "gp3ml_model_card")
  expect_s3_class(report, "gp3ml_reproducibility_report")
  expect_true(all(file.exists(c(markdown_path, json_path, reproducibility_path))))
  expect_identical(parsed$task$outcome, "quality_status")
  expect_identical(parsed$engine, "glm")
})

test_that("external validation and custom engines are governed", {
  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)
  predictors <- c("valid_gaze_prop", "fixation_count", "mean_pupil")
  model <- train_gazepoint_classifier(data, task, predictors, "glm", seed = 20260721L)

  validation <- evaluate_external_validation(
    model = model,
    external_data = data,
    label = "synthetic_external",
    bootstrap = 10L,
    seed = 20260721L
  )

  custom_fit <- function(x, y, task, args) {
    training_data <- data.frame(.outcome = y, x, check.names = FALSE)
    stats::glm(.outcome ~ ., data = training_data, family = stats::binomial())
  }
  custom_predict <- function(fit, newdata, type, task, ...) {
    as.numeric(stats::predict(fit, newdata = as.data.frame(newdata), type = "response"))
  }

  engine <- integrate_black_box_model(
    name = "custom_glm",
    fit_fun = custom_fit,
    predict_fun = custom_predict,
    supports = "classification",
    probability = TRUE,
    safety_declaration = list(
      prohibited_uses_acknowledged = TRUE,
      prediction_time_inputs_only = TRUE,
      group_aware_evaluation_required = TRUE
    )
  )

  custom_model <- train_gazepoint_classifier(
    data = data,
    task = task,
    predictors = predictors,
    engine = engine,
    seed = 20260721L
  )

  expect_s3_class(validation, "gp3ml_external_validation")
  expect_s3_class(engine, "gp3ml_engine")
  expect_s3_class(custom_model, "gp3ml_model")
})

test_that("optional deep learning fails clearly when unavailable", {
  data <- make_modeling_core_data()
  task <- make_modeling_core_task(data)

  if (!requireNamespace("keras3", quietly = TRUE)) {
    expect_error(
      fit_gazepoint_deep_model(
        data = data,
        task = task,
        predictors = c("valid_gaze_prop", "fixation_count")
      ),
      "Install `keras3`"
    )
  } else {
    succeed()
  }
})
