
test_that("integrated synthetic research bundle passes governance validation", {
  bundle <- simulate_gazepoint_research_handoffs(
    n_participants = 12L,
    n_stimuli = 3L,
    seed = 7701L
  )
  expect_s3_class(bundle, "gp3ml_research_bundle")

  validation <- validate_gazepoint_research_bundle(bundle)
  expect_s3_class(validation, "gp3ml_research_bundle_validation")
  expect_identical(validation$status, "pass")

  data <- as_gp3ml_data(validation$bundle)
  expect_true(all(c(
    "assigned_condition",
    "valid_gaze_prop",
    "eda_valid_prop",
    "sequence_length"
  ) %in% names(data)))
  expect_false(any(grepl(
    "emotion|stress|diagnos|identity|intent|cognition",
    names(data),
    ignore.case = TRUE
  )))
})

test_that("integrated bundle enters the existing governed grouped workflow", {
  bundle <- simulate_gazepoint_research_handoffs(
    n_participants = 12L,
    n_stimuli = 3L,
    seed = 7702L
  )
  validation <- validate_gazepoint_research_bundle(bundle)
  data <- as_gp3ml_data(validation$bundle)

  predictors <- c(
    "valid_gaze_prop",
    "fixation_count",
    "mean_fixation_ms",
    "gaze_dispersion",
    "eda_valid_prop",
    "hr_valid_prop",
    "ibi_valid_prop",
    "sequence_length",
    "unique_state_count",
    "transition_rate"
  )

  task <- declare_gazepoint_task(
    data = data,
    outcome = "assigned_condition",
    purpose = "Discriminate an experimentally assigned condition using predeclared observed non-sensitive Gazepoint-derived predictors",
    task_type = "classification",
    unit_id = "trial_id",
    participant_id = "participant_id",
    stimulus_id = "stimulus_id",
    generalization_target = "new_participants",
    positive = "B",
    observed_outcome = TRUE,
    sensitive_outcome = FALSE
  )

  manifest <- create_gazepoint_feature_manifest(
    features = predictors,
    scientific_source = c(
      rep("gp3tools prepared gaze/fixation summaries", 4L),
      rep("gpbiometrics prepared signal-quality summaries", 3L),
      rep("gp3sequences prepared sequence summaries", 3L)
    ),
    source_table = c(
      rep("gp3tools handoff", 4L),
      rep("gpbiometrics handoff", 3L),
      rep("gp3sequences handoff", 3L)
    ),
    transformation = "Prepared upstream summary passed through a validated interoperability handoff",
    availability_stage = "during_exposure",
    prediction_time_available = TRUE,
    outcome_derived = FALSE,
    post_outcome = FALSE,
    identifier = FALSE,
    preprocessing_scope = "none",
    fold_local_required = FALSE,
    reviewer_notes = "Synthetic shareable cross-package validation workflow."
  )

  expect_identical(
    validate_gazepoint_feature_manifest(manifest)$status,
    "pass"
  )

  folds <- create_gazepoint_group_folds(
    data = data,
    outcome = task$outcome,
    predictors = predictors,
    feature_manifest = manifest,
    generalization_target = task$generalization_target,
    participant_id = task$participant_id,
    trial_id = task$unit_id,
    stimulus_id = task$stimulus_id,
    v = 3L,
    repeats = 1L,
    seed = 7702L
  )

  expect_identical(
    validate_gazepoint_group_folds(folds)$status,
    "pass"
  )

  if ("evaluate_gazepoint_group_folds" %in% getNamespaceExports("gp3ml")) {
    evaluation <- evaluate_gazepoint_group_folds(
      folds,
      task,
      predictors,
      "glm",
      seed = 7702L
    )
    expect_identical(
      validate_gazepoint_resample_evaluation(evaluation)$status,
      "pass"
    )
  } else {
    diagnostics <- diagnose_gazepoint_group_folds(folds)
    expect_true(
      validate_gazepoint_fold_diagnostics(diagnostics)$status %in%
        c("pass", "review")
    )
  }
})
