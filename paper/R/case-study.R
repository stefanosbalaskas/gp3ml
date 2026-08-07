# Executable synthetic case study for the gp3ml paper.
# Expected to be sourced after library(gp3ml) and paper/R/helpers.R.

case_seed <- 20260807L
set.seed(case_seed)

synthetic_data <- simulate_gazepoint_governed_data(
  n_participants = 30L,
  n_stimuli = 8L,
  trials_per_cell = 2L,
  seed = case_seed
)

# Controlled predictor missingness is imposed deterministically. The outcome and
# grouping identifiers remain complete. gp3ml estimates imputation parameters
# inside each analysis partition.
analysis_data <- synthetic_data
missing_n <- max(1L, floor(0.05 * nrow(analysis_data)))
missing_rows <- sample(seq_len(nrow(analysis_data)), missing_n)
analysis_data$gaze_dispersion[missing_rows] <- NA_real_

predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
quality_task <- create_gazepoint_synthetic_task(
  analysis_data,
  workflow = "recording_quality",
  generalization_target = "new_participants"
)
feature_manifest <- create_gazepoint_synthetic_manifest(
  outcome = quality_task$outcome,
  predictors = predictors
)

analysis_plan <- declare_gazepoint_analysis_plan(
  research_question = paste(
    "How accurately can predeclared gaze-quality features identify an",
    "observed recording-quality review status for new participants?"
  ),
  scientific_purpose = paste(
    "Evaluate a transparent review classifier for an explicitly observed,",
    "non-sensitive recording-quality outcome."
  ),
  outcome = quality_task$outcome,
  outcome_definition = "Predefined synthetic pass/review recording-quality status.",
  predictors = predictors,
  generalization_target = "new_participants",
  grouping_variables = c("participant_id", "stimulus_id", "trial_id"),
  eligible_population = paste(
    "Deterministic synthetic participant-stimulus trials generated for",
    "package validation."
  ),
  exclusion_rules = paste(
    "No outcome-based exclusions; missing predictors are imputed within",
    "analysis folds."
  ),
  preprocessing_plan = list(
    numeric_imputation = "median",
    center = TRUE,
    scale = TRUE
  ),
  candidate_models = "glm",
  primary_metric = "balanced_accuracy",
  secondary_metrics = c("roc_auc", "brier", "log_loss"),
  calibration_metric = "ece",
  uncertainty_method = paste(
    "Repeated grouped-fold distribution and participant-level split",
    "conformal calibration"
  ),
  threshold_policy = paste(
    "Explicit development-partition threshold candidates with optional",
    "abstention and held-out policy audit"
  ),
  external_validation_required = FALSE,
  seed_strategy = paste0("Deterministic seed ", case_seed),
  prohibited_interpretations = gp3ml_prohibited_uses()
)
analysis_plan_validation <- validate_gazepoint_analysis_plan(analysis_plan)
locked_plan <- lock_gazepoint_analysis_plan(analysis_plan)

# Participant-grouped validation.
group_folds <- create_gazepoint_group_folds(
  data = analysis_data,
  outcome = quality_task$outcome,
  predictors = predictors,
  feature_manifest = feature_manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  v = 5L,
  repeats = 2L,
  seed = case_seed
)
group_audit <- audit_gazepoint_group_folds(group_folds)
group_diagnostics <- diagnose_gazepoint_group_folds(group_folds)

group_evaluation <- evaluate_gazepoint_group_folds(
  folds = group_folds,
  task = quality_task,
  predictors = predictors,
  engine = "glm",
  preprocessor_args = list(
    numeric_imputation = "median",
    center = TRUE,
    scale = TRUE
  ),
  threshold = 0.5,
  seed = case_seed,
  assess_calibration = TRUE,
  calibration_bins = 8L,
  calibration_bootstrap = 0L,
  keep_models = TRUE
)
group_predictions <- collect_gazepoint_fold_predictions(
  group_evaluation,
  include_failed = FALSE
)
group_metrics <- metric_distribution(
  group_evaluation$metrics,
  "Participant grouped"
)

# Crossed participant-stimulus validation.
cross_task <- create_gazepoint_synthetic_task(
  analysis_data,
  workflow = "recording_quality",
  generalization_target = "new_participants_and_new_stimuli"
)
cross_folds <- create_gazepoint_group_folds(
  data = analysis_data,
  outcome = cross_task$outcome,
  predictors = predictors,
  feature_manifest = feature_manifest,
  generalization_target = "new_participants_and_new_stimuli",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  v = c(3L, 3L),
  repeats = 1L,
  seed = case_seed
)
cross_audit <- audit_gazepoint_group_folds(cross_folds)
cross_evaluation <- evaluate_gazepoint_group_folds(
  folds = cross_folds,
  task = cross_task,
  predictors = predictors,
  engine = "glm",
  preprocessor_args = list(
    numeric_imputation = "median",
    center = TRUE,
    scale = TRUE
  ),
  threshold = 0.5,
  seed = case_seed,
  assess_calibration = FALSE,
  keep_models = FALSE
)
cross_predictions <- collect_gazepoint_fold_predictions(
  cross_evaluation,
  include_failed = FALSE
)
cross_metrics <- metric_distribution(
  cross_evaluation$metrics,
  "Participant-stimulus blocks"
)

# Intentionally unsafe row-level comparator implemented only for the paper.
naive_evaluation <- naive_row_cv_glm(
  data = analysis_data,
  outcome = quality_task$outcome,
  predictors = predictors,
  positive = quality_task$positive,
  v = 5L,
  repeats = 2L,
  seed = case_seed
)
naive_metrics <- naive_evaluation$metrics[
  , c("design", "repeat", "fold", "metric", "value")
]

all_metrics <- rbind(naive_metrics, group_metrics, cross_metrics)
performance_summary <- summarise_metric_distribution(all_metrics)

# Use a single repeated-CV pass for secondary probability diagnostics so each
# source row occurs once. Split participants again into a policy-development
# subset and a held-out policy-audit subset. No participant crosses this split.
first_repeat <- min(group_predictions[["repeat"]], na.rm = TRUE)
probability_predictions <- group_predictions[
  group_predictions[["repeat"]] == first_repeat &
    !is.na(group_predictions$truth) &
    !is.na(group_predictions$probability),
  , drop = FALSE
]
participant_levels <- sort(unique(as.character(
  probability_predictions$participant_id
)))
stopifnot(length(participant_levels) >= 4L)
policy_development_participants <- NULL
policy_audit_participants <- NULL
policy_development_predictions <- NULL
policy_audit_predictions <- NULL
for (split_offset in seq_len(100L)) {
  set.seed(case_seed + 2L + split_offset)
  candidate_development <- sort(sample(
    participant_levels,
    size = floor(length(participant_levels) / 2L),
    replace = FALSE
  ))
  candidate_audit <- setdiff(participant_levels, candidate_development)
  development_rows <- probability_predictions[
    as.character(probability_predictions$participant_id) %in%
      candidate_development,
    , drop = FALSE
  ]
  audit_rows <- probability_predictions[
    as.character(probability_predictions$participant_id) %in% candidate_audit,
    , drop = FALSE
  ]
  development_classes <- unique(as.character(development_rows$truth))
  audit_classes <- unique(as.character(audit_rows$truth))
  if (length(development_classes) == 2L && length(audit_classes) == 2L) {
    policy_development_participants <- candidate_development
    policy_audit_participants <- candidate_audit
    policy_development_predictions <- development_rows
    policy_audit_predictions <- audit_rows
    policy_split_seed <- case_seed + 2L + split_offset
    break
  }
}
stopifnot(
  !is.null(policy_development_predictions),
  !is.null(policy_audit_predictions),
  nrow(policy_development_predictions) > 0L,
  nrow(policy_audit_predictions) > 0L,
  length(intersect(
    unique(as.character(policy_development_predictions$participant_id)),
    unique(as.character(policy_audit_predictions$participant_id))
  )) == 0L
)
policy_split_summary <- data.frame(
  partition = c("Policy development", "Held-out policy audit"),
  participants = c(
    length(policy_development_participants),
    length(policy_audit_participants)
  ),
  rows = c(
    nrow(policy_development_predictions),
    nrow(policy_audit_predictions)
  ),
  split_seed = rep(policy_split_seed, 2L),
  stringsAsFactors = FALSE
)

# Calibration is descriptive assessment-fold evidence and uses predictions from
# the first grouped-CV repeat only.
calibration <- assess_gazepoint_calibration(
  truth = probability_predictions$truth,
  probability = probability_predictions$probability,
  positive = quality_task$positive,
  bins = 8L,
  bootstrap = 200L,
  seed = case_seed
)

# Conformal calibration and evaluation are separated by participant.
conformal_fit <- fit_gazepoint_conformal(
  truth = policy_development_predictions$truth,
  probability = policy_development_predictions$probability,
  task_type = "classification",
  positive = quality_task$positive,
  level = 0.90,
  calibration_unit = "participant",
  unit = policy_development_predictions$participant_id,
  generalization_target = "new_participants"
)
conformal_sets <- predict_gazepoint_set(
  conformal_fit,
  probability = policy_audit_predictions$probability
)
conformal_coverage <- assess_gazepoint_conformal_coverage(
  conformal_fit,
  truth = policy_audit_predictions$truth,
  set = conformal_sets,
  unit = policy_audit_predictions$participant_id
)
conformal_set_size <- as.integer(conformal_sets$include_negative) +
  as.integer(conformal_sets$include_positive)

# Threshold selection and the abstention policy are developed on one participant
# subset and audited on disjoint held-out participants.
threshold_evaluation <- evaluate_gazepoint_thresholds(
  truth = policy_development_predictions$truth,
  probability = policy_development_predictions$probability,
  positive = quality_task$positive,
  thresholds = seq(0.20, 0.80, by = 0.05),
  cost_false_positive = 1,
  cost_false_negative = 2
)
decision_rule <- select_gazepoint_threshold(
  threshold_evaluation,
  metric = "balanced_accuracy",
  direction = "maximize",
  threshold_origin = "training",
  training_partition = "participant-disjoint policy-development assessment predictions",
  generalization_target = "new_participants",
  scientific_justification = paste(
    "Balance sensitivity and specificity for an explicitly observed review",
    "flag while assigning a higher cost to missed review cases."
  ),
  abstention_allowed = TRUE,
  abstention_interval = c(0.15, 0.25)
)
decision_validation <- validate_gazepoint_decision_rule(
  decision_rule,
  require_threshold = TRUE
)
negative_class <- setdiff(
  sort(unique(as.character(policy_audit_predictions$truth))),
  quality_task$positive
)[[1L]]
decisions <- apply_gazepoint_decision_rule(
  decision_rule,
  probability = policy_audit_predictions$probability,
  positive = quality_task$positive,
  negative = negative_class
)
abstention_audit <- audit_gazepoint_abstention(
  policy_audit_predictions$truth,
  decisions
)

abstention_frontier <- compute_abstention_frontier(
  truth = policy_audit_predictions$truth,
  probability = policy_audit_predictions$probability,
  positive = quality_task$positive,
  threshold = decision_rule$threshold
)

# Transparent synthetic external-data perturbation.
external_data <- simulate_gazepoint_governed_data(
  n_participants = 18L,
  n_stimuli = 8L,
  trials_per_cell = 2L,
  seed = case_seed + 1L
)
external_data$tracking_ratio <- pmax(
  0,
  pmin(1, external_data$tracking_ratio - 0.08)
)
external_data$gaze_dispersion <- external_data$gaze_dispersion * 1.25
set.seed(case_seed + 2L)
external_missing <- sample(
  seq_len(nrow(external_data)),
  floor(0.18 * nrow(external_data))
)
external_data$gaze_dispersion[external_missing] <- NA_real_
shift_audit <- audit_gazepoint_dataset_shift(
  development = analysis_data,
  external = external_data,
  predictors = predictors
)
missingness_audit <- audit_gazepoint_missingness_shift(
  development = analysis_data,
  external = external_data,
  predictors = predictors
)
shift_summary <- summarize_gazepoint_shift(
  shift_audit,
  missingness_audit
)

# Compact sensitivity diagnostics.
seed_stability <- evaluate_gazepoint_seed_stability(
  seeds = c(case_seed, case_seed + 10L, case_seed + 20L),
  evaluator = function(seed) {
    folds <- create_gazepoint_group_folds(
      data = analysis_data,
      outcome = quality_task$outcome,
      predictors = predictors,
      feature_manifest = feature_manifest,
      generalization_target = "new_participants",
      participant_id = "participant_id",
      trial_id = "trial_id",
      stimulus_id = "stimulus_id",
      v = 3L,
      repeats = 1L,
      seed = seed
    )
    fit <- evaluate_gazepoint_group_folds(
      folds = folds,
      task = quality_task,
      predictors = predictors,
      engine = "glm",
      preprocessor_args = list(
        numeric_imputation = "median",
        center = TRUE,
        scale = TRUE
      ),
      seed = seed
    )
    summary_table <- summarize_gazepoint_resample_performance(fit)$summary
    value <- summary_table$mean[
      summary_table$metric == "balanced_accuracy"
    ]
    data.frame(balanced_accuracy = value)
  }
)
threshold_stability <- evaluate_gazepoint_threshold_stability(
  evaluation = threshold_evaluation,
  metric = "balanced_accuracy",
  direction = "maximize",
  tolerance = 0.02
)
robustness_audit <- audit_gazepoint_model_robustness(
  seed_stability = seed_stability,
  threshold_stability = threshold_stability
)

actual_analysis <- list(
  outcome = quality_task$outcome,
  predictors = predictors,
  generalization_target = "new_participants",
  primary_metric = "balanced_accuracy",
  secondary_metrics = c("roc_auc", "brier", "log_loss"),
  calibration_metric = "ece",
  uncertainty_method = paste(
    "Repeated grouped-fold distribution and participant-level split",
    "conformal calibration"
  ),
  threshold_policy = paste(
    "Explicit development-partition threshold candidates with optional",
    "abstention and held-out policy audit"
  ),
  candidate_models = "glm",
  preprocessing_plan = list(
    numeric_imputation = "median",
    center = TRUE,
    scale = TRUE
  )
)
plan_deviation_audit <- audit_gazepoint_plan_deviations(
  locked_plan,
  actual_analysis
)

environment_capture <- capture_gazepoint_environment(
  packages = c("gp3ml", "rmarkdown", "knitr"),
  root = repo_root
)
environment_comparison <- compare_gazepoint_environments(
  environment_capture,
  environment_capture
)

model_candidates <- lapply(
  group_evaluation$fold_results,
  function(x) x$model
)
model_indices <- which(!vapply(model_candidates, is.null, logical(1)))
stopifnot(length(model_indices) > 0L)
model_index <- model_indices[[1L]]
representative_model <- model_candidates[[model_index]]
model_artifact <- create_gazepoint_model_artifact(
  model = representative_model,
  feature_manifest = feature_manifest,
  task = quality_task,
  decision_rule = decision_rule,
  reference_data = analysis_data[predictors],
  bundle_model = requireNamespace("bundle", quietly = TRUE)
)
artifact_validation <- validate_gazepoint_model_artifact(model_artifact)

api_contracts <- gp3ml_api_contracts()
api_stability <- audit_gp3ml_api_stability(api_contracts)

# Tables saved as reproducible manuscript outputs.
dir.create(file.path(paper_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
write_csv(
  performance_summary,
  file.path(paper_dir, "tables", "performance-summary.csv")
)
write_csv(
  calibration$summary,
  file.path(paper_dir, "tables", "calibration-summary.csv")
)
write_csv(
  policy_split_summary,
  file.path(paper_dir, "tables", "policy-partition-summary.csv")
)
write_csv(
  shift_audit$findings,
  file.path(paper_dir, "tables", "dataset-shift.csv")
)
write_csv(
  plan_deviation_audit$deviations,
  file.path(paper_dir, "tables", "plan-deviations.csv")
)
