roadmap_fixture <- function(
    seed = 9001L,
    target = "new_participants",
    n_participants = 18L,
    n_stimuli = 6L,
    trials_per_cell = 1L,
    repeats = 2L) {
  data <- simulate_gazepoint_governed_data(
    n_participants = n_participants,
    n_stimuli = n_stimuli,
    trials_per_cell = trials_per_cell,
    seed = seed
  )
  predictors <- c(
    "tracking_ratio",
    "blink_rate",
    "fixation_duration",
    "gaze_dispersion",
    "pupil_change"
  )
  task <- create_gazepoint_synthetic_task(
    data,
    workflow = "recording_quality",
    generalization_target = target
  )
  manifest <- create_gazepoint_synthetic_manifest(
    outcome = task$outcome,
    predictors = predictors
  )
  folds <- create_gazepoint_group_folds(
    data = data,
    outcome = task$outcome,
    predictors = predictors,
    feature_manifest = manifest,
    generalization_target = target,
    participant_id = "participant_id",
    trial_id = "trial_id",
    stimulus_id = "stimulus_id",
    v = 3L,
    repeats = repeats,
    seed = seed
  )
  list(
    data = data,
    predictors = predictors,
    task = task,
    manifest = manifest,
    folds = folds
  )
}
