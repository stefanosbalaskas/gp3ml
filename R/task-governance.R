#' Prohibited gp3ml uses
#'
#'
#' @examples
#' gp3ml_prohibited_uses()
#' @return A character vector of prohibited use descriptions.
#' @export
gp3ml_prohibited_uses <- function() {
  c(
    "person identification or re-identification",
    "biometric authentication or verification",
    "health, disease, disability, or diagnostic inference",
    "protected-attribute prediction or proxy prediction",
    "emotion, stress, personality, deception, cognition, comprehension, intent, or mental-state inference",
    "random row-level evaluation represented as participant- or stimulus-level generalization",
    "outcome-derived or post-outcome feature engineering",
    "preprocessing estimated using assessment or external-validation data",
    "accuracy-only reporting without discrimination, calibration, and uncertainty"
  )
}

.gp3ml_prohibited_pattern <- paste(
  c(
    "identif", "re-identif", "authenticat", "verif.*person", "biometric",
    "diagnos", "disease", "health status", "disability", "protected",
    "race", "ethnic", "religion", "gender identity", "sexual orientation",
    "emotion", "stress", "personality", "deception", "lie detect",
    "cognition", "cognitive", "comprehension", "intent", "mental state",
    "depression", "anxiety", "adhd", "autism", "intelligence"
  ),
  collapse = "|"
)

#' Declare a governed Gazepoint prediction task
#'
#'
#' @param data A data frame containing the outcome and task identifiers.
#' @param outcome Name of the explicitly observed outcome column.
#' @param purpose One explicit scientific-purpose statement.
#' @param task_type Either `classification` or `regression`.
#' @param unit_id Column identifying the prediction unit.
#' @param participant_id Optional participant-identifier column.
#' @param stimulus_id Optional stimulus-identifier column.
#' @param generalization_target The intended target of generalization.
#' @param positive Positive outcome level for binary classification.
#' @param observed_outcome Whether the outcome was directly observed.
#' @param sensitive_outcome Whether the outcome is sensitive or prohibited.
#'
#' @examples
#' example_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   condition = rep(c("A", "B"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' example_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = example_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' task
#' @return A governed `gp3ml_task` object describing the outcome, scientific purpose, prediction unit, grouping roles, task type, and generalization target.
#' @export
declare_gazepoint_task <- function(
    data,
    outcome,
    purpose,
    task_type = c("classification", "regression"),
    unit_id,
    participant_id = NULL,
    stimulus_id = NULL,
    generalization_target = c(
      "new_trials_known_participants",
      "new_participants",
      "new_stimuli",
      "new_participants_and_new_stimuli",
      "external_validation"
    ),
    positive = NULL,
    observed_outcome = TRUE,
    sensitive_outcome = FALSE) {
  .gp3ml_assert_data(data)
  task_type <- match.arg(task_type)
  generalization_target <- match.arg(generalization_target)
  if (length(outcome) != 1L || !nzchar(outcome)) .gp3ml_stop("Supply one `outcome` column.")
  if (length(unit_id) != 1L || !nzchar(unit_id)) .gp3ml_stop("Supply one `unit_id` column.")
  .gp3ml_assert_columns(
    data,
    c(outcome, unit_id, participant_id, stimulus_id),
    "task columns"
  )
  if (!is.character(purpose) || length(purpose) != 1L || !nzchar(trimws(purpose))) {
    .gp3ml_stop("`purpose` must be one explicit scientific-purpose statement.")
  }
  task <- structure(
    list(
      outcome = outcome,
      purpose = purpose,
      task_type = task_type,
      unit_id = unit_id,
      participant_id = participant_id,
      stimulus_id = stimulus_id,
      generalization_target = generalization_target,
      positive = positive,
      observed_outcome = isTRUE(observed_outcome),
      sensitive_outcome = isTRUE(sensitive_outcome),
      created_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    class = "gp3ml_task"
  )
  assert_gp3ml_use_case(task, data)
  if (task_type == "classification") {
    values <- data[[outcome]]
    levels_found <- if (is.factor(values)) levels(values) else sort(unique(as.character(values[!is.na(values)])))
    if (length(levels_found) != 2L) {
      .gp3ml_stop("Initial classification support requires exactly two observed outcome levels.")
    }
    task$levels <- levels_found
    task$positive <- positive %||% levels_found[[2L]]
    if (!task$positive %in% levels_found) .gp3ml_stop("`positive` is not an outcome level.")
    task$negative <- setdiff(levels_found, task$positive)[[1L]]
  } else {
    if (!is.numeric(data[[outcome]])) .gp3ml_stop("Regression outcomes must be numeric.")
    task$levels <- NULL
    task$positive <- NULL
    task$negative <- NULL
  }
  task
}

#' Assert that a task is within the permitted gp3ml scope
#'
#'
#' @param task A `gp3ml_task` object.
#' @param data Optional data frame used to validate task columns.
#'
#' @examples
#' example_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   condition = rep(c("A", "B"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' example_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = example_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' assert_gp3ml_use_case(task, example_data)
#' @return Invisibly returns `TRUE` when the task is permitted; otherwise, the function stops with an error.
#' @export
assert_gp3ml_use_case <- function(task, data = NULL) {
  if (!inherits(task, "gp3ml_task")) .gp3ml_stop("`task` must be a gp3ml task declaration.")
  text <- tolower(paste(task$purpose, task$outcome, collapse = " "))
  if (isTRUE(task$sensitive_outcome) || grepl(.gp3ml_prohibited_pattern, text, perl = TRUE)) {
    .gp3ml_stop(
      "This task is prohibited. gp3ml does not support identification, authentication, health/diagnostic, protected-attribute, or inferred emotion/cognition/intent uses."
    )
  }
  if (!isTRUE(task$observed_outcome)) {
    .gp3ml_stop("The outcome must be explicitly observed rather than inferred as a latent mental or sensitive state.")
  }
  if (task$generalization_target == "new_participants" && is.null(task$participant_id)) {
    .gp3ml_stop("Participant-level generalization requires `participant_id`.")
  }
  if (task$generalization_target == "new_stimuli" && is.null(task$stimulus_id)) {
    .gp3ml_stop("Stimulus-level generalization requires `stimulus_id`.")
  }
  if (task$generalization_target == "new_participants_and_new_stimuli" &&
      (is.null(task$participant_id) || is.null(task$stimulus_id))) {
    .gp3ml_stop("Crossed generalization requires participant and stimulus identifiers.")
  }
  if (!is.null(data)) {
    .gp3ml_assert_columns(data, c(task$outcome, task$unit_id, task$participant_id, task$stimulus_id), "task columns")
  }
  invisible(TRUE)
}

#' @method print gp3ml_task
#' @export
print.gp3ml_task <- function(x, ...) {
  cat("<gp3ml_task>\n")
  cat("  type: ", x$task_type, "\n", sep = "")
  cat("  outcome: ", x$outcome, "\n", sep = "")
  cat("  target: ", x$generalization_target, "\n", sep = "")
  cat("  purpose: ", x$purpose, "\n", sep = "")
  invisible(x)
}

#' Validate outcome, predictor, identifier, and grouping roles
#'
#'
#' @param data A data frame containing outcome, predictors, and identifiers.
#' @param task A governed `gp3ml_task` object.
#' @param predictors Character vector naming intended predictors.
#' @param feature_manifest Optional Gazepoint feature-provenance manifest.
#'
#' @examples
#' example_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   condition = rep(c("A", "B"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' example_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = example_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint all-gaze export"
#'   ),
#'   source_table = c("fixations", "all_gaze"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Baseline-adjusted change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = c("none", "resampling_fold"),
#'   fold_local_required = c(FALSE, TRUE)
#' )
#'
#' validate_gazepoint_ml_roles(
#'   data = example_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   feature_manifest = manifest
#' )
#' @return A `gp3ml_role_validation` object containing the overall status, complete check table, non-passing issues, and optional feature-manifest validation.
#' @export
validate_gazepoint_ml_roles <- function(data, task, predictors, feature_manifest = NULL) {
  .gp3ml_assert_data(data)
  assert_gp3ml_use_case(task, data)
  predictors <- unique(as.character(predictors))
  missing_predictors <- setdiff(predictors, names(data))
  identifiers <- c(task$unit_id, task$participant_id, task$stimulus_id)
  identifiers <- identifiers[!is.na(identifiers) & nzchar(identifiers)]
  class_counts <- if (task$task_type == "classification") table(data[[task$outcome]], useNA = "no") else NULL
  grouping_column <- switch(
    task$generalization_target,
    new_trials_known_participants = task$unit_id,
    new_participants = task$participant_id,
    new_stimuli = task$stimulus_id,
    new_participants_and_new_stimuli = task$participant_id,
    external_validation = task$unit_id
  )
  manifest_validation <- if (is.null(feature_manifest)) NULL else validate_gazepoint_feature_manifest(feature_manifest)
  checks <- data.frame(
    check = c(
      "predictors_exist",
      "outcome_not_predictor",
      "identifiers_not_predictors",
      "outcome_complete",
      "sufficient_group_levels",
      "classification_level_support",
      "feature_manifest"
    ),
    status = c(
      if (length(missing_predictors)) "fail" else "pass",
      if (task$outcome %in% predictors) "fail" else "pass",
      if (length(intersect(predictors, identifiers))) "fail" else "pass",
      if (anyNA(data[[task$outcome]])) "fail" else "pass",
      if (is.null(grouping_column) || length(unique(data[[grouping_column]])) < 2L) "fail" else "pass",
      if (task$task_type != "classification") "pass" else if (length(class_counts) != 2L || any(class_counts < 2L)) "fail" else if (any(class_counts < 10L)) "review" else "pass",
      if (is.null(manifest_validation)) "review" else manifest_validation$status
    ),
    detail = c(
      paste(missing_predictors, collapse = ", "),
      paste(intersect(task$outcome, predictors), collapse = ", "),
      paste(intersect(predictors, identifiers), collapse = ", "),
      as.character(sum(is.na(data[[task$outcome]]))),
      if (is.null(grouping_column)) "missing grouping role" else as.character(length(unique(data[[grouping_column]]))),
      if (is.null(class_counts)) "not applicable" else paste(names(class_counts), class_counts, sep = "=", collapse = ", "),
      if (is.null(manifest_validation)) "manifest not supplied" else manifest_validation$status
    ),
    stringsAsFactors = FALSE
  )
  structure(
    list(
      status = if (any(checks$status == "fail")) "fail" else if (any(checks$status == "review")) "review" else "pass",
      checks = checks,
      issues = checks[checks$status != "pass", , drop = FALSE],
      manifest_validation = manifest_validation
    ),
    class = "gp3ml_role_validation"
  )
}

#' @method print gp3ml_role_validation
#' @export
print.gp3ml_role_validation <- function(x, ...) {
  cat("<gp3ml_role_validation> ", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}
