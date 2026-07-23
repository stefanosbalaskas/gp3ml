#!/usr/bin/env Rscript

stopifnot(requireNamespace("pkgload", quietly = TRUE))
repository <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repository, "DESCRIPTION"))) {
  stop("Run this script from the gp3ml repository root.", call. = FALSE)
}

if ("gp3ml" %in% loadedNamespaces()) pkgload::unload("gp3ml")
pkgload::load_all(repository, attach = TRUE, export_all = FALSE, quiet = TRUE)
stopifnot("package:gp3ml" %in% search())

required_exports <- c(
  "simulate_gazepoint_governed_data",
  "create_gazepoint_synthetic_manifest",
  "create_gazepoint_synthetic_task",
  "evaluate_gazepoint_group_folds",
  "collect_gazepoint_fold_predictions",
  "summarize_gazepoint_resample_performance",
  "validate_gazepoint_resample_evaluation",
  "create_gazepoint_tuning_grid",
  "tune_gazepoint_model",
  "compare_gazepoint_models",
  "select_gazepoint_model",
  "create_gazepoint_nested_folds",
  "audit_gazepoint_nested_resampling",
  "evaluate_gazepoint_nested_resampling",
  "bootstrap_gazepoint_metrics_by_unit",
  "summarize_gazepoint_resample_uncertainty",
  "declare_gazepoint_external_dataset",
  "evaluate_gazepoint_external_transportability",
  "create_gazepoint_release_model_card",
  "write_gazepoint_release_model_card"
)
stopifnot(all(required_exports %in% getNamespaceExports("gp3ml")))

synthetic <- simulate_gazepoint_governed_data(15L, 6L, 1L, 3101L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(
  synthetic,
  "recording_quality",
  "new_participants"
)
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data = synthetic,
  outcome = task$outcome,
  predictors = predictors,
  feature_manifest = manifest,
  generalization_target = task$generalization_target,
  participant_id = task$participant_id,
  trial_id = task$unit_id,
  stimulus_id = task$stimulus_id,
  v = 3L,
  repeats = 1L,
  seed = 3101L
)
stopifnot(identical(folds$validation$status, "pass"))

evaluation <- evaluate_gazepoint_group_folds(
  folds,
  task,
  predictors = predictors,
  engine = "glm",
  seed = 3101L,
  assess_calibration = TRUE,
  calibration_bootstrap = 0L
)
stopifnot(
  inherits(evaluation, "gp3ml_resample_evaluation"),
  nrow(evaluation$predictions) > 0L,
  all(evaluation$predictions$stage == "assessment"),
  !any(evaluation$fold_status$status == "fail")
)

grid <- create_gazepoint_tuning_grid(
  "glm",
  preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
  thresholds = c(0.45, 0.55),
  complexity = seq_len(4L),
  interpretability = "high"
)
tuning <- tune_gazepoint_model(
  folds,
  task,
  grid,
  predictors = predictors,
  seed = 3101L
)
stopifnot(
  length(tuning$results) == nrow(grid$candidates),
  is.null(tuning$selection)
)
selection <- select_gazepoint_model(
  tuning,
  metric = "brier",
  direction = "minimize",
  minimum_success_prop = 0.5,
  rationale = "Predeclared calibration-sensitive metric with human review."
)
stopifnot(inherits(selection, "gp3ml_model_selection"))

nested <- create_gazepoint_nested_folds(
  folds,
  inner_v = 2L,
  inner_repeats = 1L,
  seed = 3101L
)
stopifnot(identical(nested$audit$status, "pass"))
nested_evaluation <- evaluate_gazepoint_nested_resampling(
  nested,
  task,
  grid,
  selection_metric = "brier",
  direction = "minimize",
  predictors = predictors,
  minimum_success_prop = 0.5,
  seed = 3101L
)
stopifnot(
  inherits(nested_evaluation, "gp3ml_nested_evaluation"),
  all(nested_evaluation$predictions$stage == "outer_assessment")
)

predictions <- evaluation$predictions
uncertainty <- bootstrap_gazepoint_metrics_by_unit(
  task,
  truth = predictions$truth,
  prediction = factor(predictions$prediction, levels = levels(synthetic$quality_status)),
  probability = predictions$probability,
  participant_id = predictions$participant_id,
  unit = "participant",
  bootstrap = 25L,
  seed = 3101L
)
stopifnot(
  identical(uncertainty$unit, "participant"),
  uncertainty$successful_replicates > 0L
)

model <- fit_gazepoint_model(
  synthetic,
  task,
  predictors,
  "glm",
  seed = 3101L
)
not_validated <- evaluate_gazepoint_external_transportability(
  model,
  development_data = synthetic,
  external_data = NULL
)
stopifnot(identical(not_validated$status, "not_externally_validated"))

external <- simulate_gazepoint_governed_data(8L, 6L, 1L, 3102L)
external$participant_id <- paste0("E", external$participant_id)
external$trial_id <- paste0("E", external$trial_id)
external$stimulus_id <- paste0("E", external$stimulus_id)
declaration <- declare_gazepoint_external_dataset(
  external,
  "smoke_external",
  independent = TRUE,
  origin = "Independent deterministic synthetic generation"
)
transportability <- evaluate_gazepoint_external_transportability(
  model,
  development_data = synthetic,
  external_data = external,
  declaration = declaration,
  development_evaluation = evaluation,
  bootstrap = 0L,
  seed = 3102L
)
stopifnot(identical(transportability$status, "externally_validated"))

card <- create_gazepoint_release_model_card(
  model,
  intended_use = "Support manual review of predefined recording-quality status.",
  evaluation = evaluation,
  selection = selection,
  uncertainty = uncertainty,
  feature_manifest = manifest,
  transportability = transportability,
  limitations = "Deterministic synthetic smoke test only."
)
card_path <- tempfile(fileext = ".md")
write_gazepoint_release_model_card(card, card_path)
stopifnot(file.exists(card_path), file.info(card_path)$size > 0L)
unlink(card_path)

cat(
  "ROADMAP SMOKE TEST PASSED.\n",
  "Fold evaluation, explicit tuning, nested resampling, target-aligned uncertainty,\n",
  "transportability reporting, and release model-card generation all completed.\n",
  sep = ""
)
