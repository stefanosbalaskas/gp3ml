#' Simulate governed synthetic Gazepoint-derived data
#'
#' Creates deterministic, non-sensitive synthetic data for package examples,
#' tests, and website articles. The generated outcomes are explicitly observed:
#' a predefined recording-quality review status, an experimentally assigned
#' condition, and a non-sensitive recorded response.
#'
#' @param n_participants Number of synthetic participants.
#' @param n_stimuli Number of synthetic stimuli.
#' @param trials_per_cell Number of trials per participant-stimulus cell.
#' @param seed Deterministic random seed.
#'
#' @return A data frame containing identifiers, observed outcomes, and
#'   predeclared synthetic predictors.
#' @examples
#' synthetic <- simulate_gazepoint_governed_data(
#'   n_participants = 12L,
#'   n_stimuli = 4L,
#'   trials_per_cell = 1L,
#'   seed = 101L
#' )
#' table(synthetic$quality_status)
#' @export
simulate_gazepoint_governed_data <- function(
    n_participants = 30L,
    n_stimuli = 8L,
    trials_per_cell = 2L,
    seed = 1L) {
  n_participants <- as.integer(n_participants)
  n_stimuli <- as.integer(n_stimuli)
  trials_per_cell <- as.integer(trials_per_cell)
  if (n_participants < 4L) .gp3ml_stop("`n_participants` must be at least 4.")
  if (n_stimuli < 2L) .gp3ml_stop("`n_stimuli` must be at least 2.")
  if (trials_per_cell < 1L) .gp3ml_stop("`trials_per_cell` must be positive.")

  restore <- .gp3ml_set_seed(seed)
  on.exit(restore(), add = TRUE)

  design <- expand.grid(
    participant_id = sprintf("P%03d", seq_len(n_participants)),
    stimulus_id = sprintf("S%03d", seq_len(n_stimuli)),
    replicate = seq_len(trials_per_cell),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  design <- design[order(design$participant_id, design$stimulus_id, design$replicate), ]
  rownames(design) <- NULL
  n <- nrow(design)
  design$trial_id <- sprintf("T%05d", seq_len(n))

  participant_index <- match(
    design$participant_id,
    sprintf("P%03d", seq_len(n_participants))
  )
  stimulus_index <- match(
    design$stimulus_id,
    sprintf("S%03d", seq_len(n_stimuli))
  )
  participant_effect <- stats::rnorm(n_participants, 0, 0.35)
  stimulus_effect <- stats::rnorm(n_stimuli, 0, 0.25)

  design$assigned_condition <- factor(
    ifelse((participant_index + stimulus_index + design$replicate) %% 2L == 0L, "B", "A"),
    levels = c("A", "B")
  )
  design$tracking_ratio <- pmin(
    1,
    pmax(
      0.45,
      0.92 + participant_effect[participant_index] * 0.04 -
        abs(stimulus_effect[stimulus_index]) * 0.03 + stats::rnorm(n, 0, 0.035)
    )
  )
  design$blink_rate <- pmax(
    0,
    6 + participant_effect[participant_index] * 1.2 +
      stimulus_effect[stimulus_index] * 0.8 + stats::rnorm(n, 0, 1.2)
  )
  design$fixation_duration <- pmax(
    80,
    215 + 18 * (design$assigned_condition == "B") +
      participant_effect[participant_index] * 28 +
      stimulus_effect[stimulus_index] * 22 + stats::rnorm(n, 0, 18)
  )
  design$gaze_dispersion <- pmax(
    0.05,
    1.1 - 0.35 * design$tracking_ratio +
      participant_effect[participant_index] * 0.08 + stats::rnorm(n, 0, 0.12)
  )
  design$pupil_change <-
    0.10 * (design$assigned_condition == "B") +
    participant_effect[participant_index] * 0.18 +
    stimulus_effect[stimulus_index] * 0.12 + stats::rnorm(n, 0, 0.18)

  quality_score <-
    -4.2 + 5.0 * (1 - design$tracking_ratio) +
    0.22 * design$blink_rate + 0.85 * design$gaze_dispersion
  quality_probability <- stats::plogis(quality_score)
  design$quality_status <- factor(
    ifelse(
      stats::runif(n) < quality_probability,
      "review",
      "pass"
    ),
    levels = c("pass", "review")
  )

  response_probability <- stats::plogis(
    -0.25 + 0.60 * (design$assigned_condition == "B") +
      0.003 * (design$fixation_duration - 215) -
      0.45 * design$gaze_dispersion +
      participant_effect[participant_index] * 0.25
  )
  design$observed_response <- factor(
    ifelse(stats::runif(n) < response_probability, "recorded_yes", "recorded_no"),
    levels = c("recorded_no", "recorded_yes")
  )
  design$observed_duration <- pmax(
    0.1,
    exp(
      1.8 - 0.10 * (design$assigned_condition == "B") +
        0.25 * design$gaze_dispersion +
        participant_effect[participant_index] * 0.12 +
        stats::rnorm(n, 0, 0.22)
    )
  )
  design$site_label <- factor(
    ifelse(stimulus_index <= ceiling(n_stimuli / 2), "development_site", "external_site")
  )

  design[c(
    "participant_id", "trial_id", "stimulus_id", "replicate",
    "assigned_condition", "tracking_ratio", "blink_rate",
    "fixation_duration", "gaze_dispersion", "pupil_change",
    "quality_status", "observed_response", "observed_duration",
    "site_label"
  )]
}

#' Create a synthetic governed feature manifest
#'
#' @param outcome Name of the observed synthetic outcome.
#' @param predictors Predictor names to declare.
#' @param participant_id Participant identifier column.
#' @param stimulus_id Stimulus identifier column.
#' @param trial_id Trial identifier column.
#'
#' @return A `gazepoint_feature_manifest` produced by
#'   [create_gazepoint_feature_manifest()].
#' @examples
#' create_gazepoint_synthetic_manifest(
#'   outcome = "quality_status",
#'   predictors = c("tracking_ratio", "blink_rate", "gaze_dispersion")
#' )
#' @export
create_gazepoint_synthetic_manifest <- function(
    outcome,
    predictors,
    participant_id = "participant_id",
    stimulus_id = "stimulus_id",
    trial_id = "trial_id") {
  create_gazepoint_feature_manifest(
    features = predictors,
    scientific_source = rep("Deterministic synthetic demonstration", length(predictors)),
    source_table = rep("synthetic_trial_features", length(predictors)),
    transformation = rep("Predeclared synthetic feature", length(predictors)),
    availability_stage = rep("during_exposure", length(predictors)),
    prediction_time_available = rep(TRUE, length(predictors)),
    outcome_derived = rep(FALSE, length(predictors)),
    post_outcome = rep(FALSE, length(predictors)),
    identifier = rep(FALSE, length(predictors)),
    preprocessing_scope = rep("resampling_fold", length(predictors)),
    fold_local_required = rep(TRUE, length(predictors)),
    reviewer_notes = rep(
      sprintf("Outcome `%s` is explicitly observed and is not a predictor.", outcome),
      length(predictors)
    )
  )
}

#' Create one of the governed synthetic demonstration tasks
#'
#' @param data Synthetic data from [simulate_gazepoint_governed_data()].
#' @param workflow Workflow name.
#' @param generalization_target Declared generalization target.
#'
#' @return A governed `gp3ml_task`.
#' @examples
#' synthetic <- simulate_gazepoint_governed_data(12L, 4L, 1L, 101L)
#' create_gazepoint_synthetic_task(
#'   synthetic,
#'   workflow = "recording_quality",
#'   generalization_target = "new_participants"
#' )
#' @export
create_gazepoint_synthetic_task <- function(
    data,
    workflow = c("recording_quality", "assigned_condition", "observed_behavior", "observed_duration"),
    generalization_target = c(
      "new_trials_known_participants",
      "new_participants",
      "new_stimuli",
      "new_participants_and_new_stimuli"
    )) {
  workflow <- match.arg(workflow)
  generalization_target <- match.arg(generalization_target)
  specification <- switch(
    workflow,
    recording_quality = list(
      outcome = "quality_status",
      purpose = "Predict predefined recording-quality review status",
      task_type = "classification",
      positive = "review"
    ),
    assigned_condition = list(
      outcome = "assigned_condition",
      purpose = "Discriminate the experimentally assigned condition using predeclared features",
      task_type = "classification",
      positive = "B"
    ),
    observed_behavior = list(
      outcome = "observed_response",
      purpose = "Predict an explicitly recorded non-sensitive response",
      task_type = "classification",
      positive = "recorded_yes"
    ),
    observed_duration = list(
      outcome = "observed_duration",
      purpose = "Predict an explicitly recorded non-sensitive duration",
      task_type = "regression",
      positive = NULL
    )
  )
  declare_gazepoint_task(
    data = data,
    outcome = specification$outcome,
    purpose = specification$purpose,
    task_type = specification$task_type,
    unit_id = "trial_id",
    participant_id = "participant_id",
    stimulus_id = "stimulus_id",
    generalization_target = generalization_target,
    positive = specification$positive,
    observed_outcome = TRUE,
    sensitive_outcome = FALSE
  )
}
