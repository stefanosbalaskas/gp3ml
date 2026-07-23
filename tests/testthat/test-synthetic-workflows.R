test_that("synthetic workflows are deterministic and governed", {
  a <- simulate_gazepoint_governed_data(12L, 4L, 1L, 1101L)
  b <- simulate_gazepoint_governed_data(12L, 4L, 1L, 1101L)
  expect_identical(a, b)
  expect_true(all(c(
    "participant_id", "trial_id", "stimulus_id", "quality_status",
    "assigned_condition", "observed_response", "observed_duration"
  ) %in% names(a)))
  expect_identical(levels(a$quality_status), c("pass", "review"))
  expect_true(all(a$observed_duration > 0))

  task <- create_gazepoint_synthetic_task(a, "recording_quality", "new_participants")
  expect_s3_class(task, "gp3ml_task")
  expect_identical(task$outcome, "quality_status")
  expect_identical(task$generalization_target, "new_participants")

  manifest <- create_gazepoint_synthetic_manifest(
    "quality_status",
    c("tracking_ratio", "blink_rate")
  )
  expect_s3_class(manifest, "gazepoint_feature_manifest")
  validation <- validate_gazepoint_feature_manifest(manifest)
  expect_true(validation$status %in% c("pass", "review"))
})

test_that("every governed synthetic target can be declared", {
  data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 1102L)
  targets <- c(
    "new_trials_known_participants",
    "new_participants",
    "new_stimuli",
    "new_participants_and_new_stimuli"
  )
  tasks <- lapply(targets, function(target) {
    create_gazepoint_synthetic_task(data, "observed_behavior", target)
  })
  expect_true(all(vapply(tasks, inherits, logical(1), "gp3ml_task")))
  expect_identical(vapply(tasks, `[[`, character(1), "generalization_target"), targets)
})

test_that("contaminated feature provenance is rejected", {
  contaminated <- create_gazepoint_feature_manifest(
    features = c("tracking_ratio", "outcome_summary"),
    scientific_source = c("Synthetic export", "Observed outcome"),
    source_table = c("trial_features", "outcome_table"),
    transformation = c("Predeclared", "Post-outcome aggregation"),
    availability_stage = c("during_exposure", "post_outcome"),
    prediction_time_available = c(TRUE, FALSE),
    outcome_derived = c(FALSE, TRUE),
    post_outcome = c(FALSE, TRUE),
    identifier = FALSE,
    preprocessing_scope = c("resampling_fold", "none"),
    fold_local_required = c(TRUE, FALSE),
    reviewer_notes = c("Permitted", "Deliberate contamination")
  )
  validation <- validate_gazepoint_feature_manifest(contaminated)
  expect_identical(validation$status, "fail")
  expect_true(any(validation$checks$status == "fail"))
})
