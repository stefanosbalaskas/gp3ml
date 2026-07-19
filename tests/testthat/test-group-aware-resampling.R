make_group_resampling_data <- function() {
  data <- expand.grid(
    participant_id = sprintf("P%02d", 1:6),
    stimulus_id = sprintf("S%02d", 1:4),
    repetition = 1:3,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  data$trial_id <- paste0(data$stimulus_id, "_T", data$repetition)
  row_index <- seq_len(nrow(data))
  data$outcome <- as.integer(row_index %% 2L)
  data$fixation_duration <- 180 + row_index
  data$pupil_change <- row_index / 1000
  data$repetition <- NULL
  data
}


make_group_resampling_manifest <- function() {
  create_gazepoint_feature_manifest(
    features = c("fixation_duration", "pupil_change"),
    scientific_source = c(
      "Gazepoint fixation export",
      "Gazepoint all-gaze export"
    ),
    source_table = c("fixations", "all_gaze"),
    transformation = c("Trial-level mean", "Baseline-adjusted change"),
    availability_stage = "during_exposure",
    prediction_time_available = TRUE,
    outcome_derived = FALSE,
    post_outcome = FALSE,
    identifier = FALSE,
    preprocessing_scope = "none",
    fold_local_required = FALSE,
    reviewer_notes = ""
  )
}


run_group_resampling <- function(
    generalization_target,
    v = 3L,
    repeats = 2L,
    seed = 101L) {
  create_gazepoint_group_folds(
    data = make_group_resampling_data(),
    outcome = "outcome",
    predictors = c("fixation_duration", "pupil_change"),
    feature_manifest = make_group_resampling_manifest(),
    generalization_target = generalization_target,
    participant_id = "participant_id",
    trial_id = "trial_id",
    stimulus_id = "stimulus_id",
    v = v,
    repeats = repeats,
    seed = seed
  )
}


assessment_counts <- function(plan) {
  result <- stats::aggregate(
    as.integer(plan$assignments$partition == "assessment"),
    by = list(
      `repeat` = plan$assignments[["repeat"]],
      source_row = plan$assignments$source_row
    ),
    FUN = sum
  )
  names(result)[3L] <- "n_assessment"
  result
}


test_that("participant folds are deterministic and disjoint", {
  first <- run_group_resampling("new_participants", seed = 77L)
  second <- run_group_resampling("new_participants", seed = 77L)

  expect_s3_class(first, "gazepoint_group_folds")
  expect_identical(first$assignments, second$assignments)
  expect_identical(first$group_mapping, second$group_mapping)
  expect_identical(first$validation$status, "pass")

  for (fold_object in first$folds) {
    expect_length(intersect(
      unique(fold_object$analysis$participant_id),
      unique(fold_object$assessment$participant_id)
    ), 0L)
    expect_identical(nrow(fold_object$excluded), 0L)
  }
})


test_that("stimulus folds are disjoint and fully covered", {
  plan <- run_group_resampling("new_stimuli")

  for (fold_object in plan$folds) {
    expect_length(intersect(
      unique(fold_object$analysis$stimulus_id),
      unique(fold_object$assessment$stimulus_id)
    ), 0L)
  }

  expect_true(all(assessment_counts(plan)$n_assessment == 1L))
  expect_identical(plan$audit$status, "pass")
})


test_that("participant-trial units remain intact", {
  plan <- run_group_resampling("new_trials_known_participants")
  participants <- sort(unique(make_group_resampling_data()$participant_id))

  for (fold_object in plan$folds) {
    analysis_units <- paste(
      fold_object$analysis$participant_id,
      fold_object$analysis$trial_id,
      sep = "::"
    )
    assessment_units <- paste(
      fold_object$assessment$participant_id,
      fold_object$assessment$trial_id,
      sep = "::"
    )

    expect_length(intersect(
      unique(analysis_units),
      unique(assessment_units)
    ), 0L)
    expect_identical(
      sort(unique(fold_object$assessment$participant_id)),
      participants
    )
  }

  expect_true(all(assessment_counts(plan)$n_assessment == 1L))
  expect_identical(plan$validation$status, "pass")
})


test_that("dual folds use strict crossed blocks", {
  plan <- run_group_resampling(
    "new_participants_and_new_stimuli",
    v = c(3L, 2L),
    repeats = 2L
  )

  expect_identical(plan$metadata$n_folds_per_repeat, 6L)
  expect_identical(plan$metadata$n_folds_total, 12L)
  expect_identical(length(plan$folds), 12L)
  expect_true(all(assessment_counts(plan)$n_assessment == 1L))

  for (fold_object in plan$folds) {
    expect_length(intersect(
      unique(fold_object$analysis$participant_id),
      unique(fold_object$assessment$participant_id)
    ), 0L)
    expect_length(intersect(
      unique(fold_object$analysis$stimulus_id),
      unique(fold_object$assessment$stimulus_id)
    ), 0L)
    expect_gt(nrow(fold_object$excluded), 0L)
  }

  expect_identical(plan$validation$status, "pass")
})


test_that("repeats, RNG restoration, and audit aggregation work", {
  set.seed(991L)
  previous_seed <- .Random.seed
  plan <- run_group_resampling("new_participants", repeats = 3L, seed = 42L)

  expect_identical(.Random.seed, previous_seed)
  expect_identical(sort(unique(plan$assignments[["repeat"]])), 1:3)
  expect_identical(nrow(plan$fold_summary), 9L)
  expect_identical(length(plan$folds), 9L)
  expect_false(anyDuplicated(plan$fold_summary$fold_id) > 0L)

  audit <- audit_gazepoint_group_folds(plan)
  expect_s3_class(audit, "gazepoint_group_folds_audit")
  expect_identical(audit$status, "pass")
  expect_identical(nrow(audit$summary), length(plan$folds))
  expect_identical(nrow(audit$issues), 0L)
})


test_that("validation detects assignment damage", {
  plan <- run_group_resampling("new_participants")
  position <- which(plan$assignments$partition == "assessment")[[1L]]
  plan$assignments$partition[position] <- "analysis"
  validation <- validate_gazepoint_group_folds(plan)

  expect_identical(validation$status, "fail")
  expect_identical(
    validation$checks$status[
      validation$checks$check_id == "assessment_coverage_once_per_repeat"
    ],
    "fail"
  )
  expect_identical(
    validation$checks$status[
      validation$checks$check_id ==
        "materialized_partitions_match_assignments"
    ],
    "fail"
  )
})


test_that("manifest, identifiers, and fold counts are enforced", {
  data <- make_group_resampling_data()
  manifest <- make_group_resampling_manifest()

  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = "fixation_duration",
    feature_manifest = NULL,
    generalization_target = "new_participants",
    participant_id = "participant_id",
    v = 3L
  ), "feature_manifest", fixed = TRUE)

  unsafe <- manifest
  unsafe$outcome_derived[1L] <- TRUE
  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = c("fixation_duration", "pupil_change"),
    feature_manifest = unsafe,
    generalization_target = "new_participants",
    participant_id = "participant_id",
    v = 3L
  ), "must pass validation", fixed = TRUE)

  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = c("fixation_duration", "pupil_change"),
    feature_manifest = manifest,
    generalization_target = "new_participants",
    participant_id = NULL,
    v = 3L
  ), "Required grouping identifiers", fixed = TRUE)

  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = c("fixation_duration", "pupil_change"),
    feature_manifest = manifest,
    generalization_target = "new_stimuli",
    stimulus_id = "stimulus_id",
    v = 5L
  ), "exceeds", fixed = TRUE)

  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = c("fixation_duration", "pupil_change"),
    feature_manifest = manifest,
    generalization_target = "new_participants",
    participant_id = "participant_id",
    v = c(2L, 3L)
  ), "single integer", fixed = TRUE)
})


test_that("trial folds require sufficient units per participant", {
  data <- data.frame(
    participant_id = rep(c("P01", "P02"), each = 2),
    trial_id = rep(c("T01", "T02"), 2),
    outcome = c(0, 1, 0, 1),
    fixation_duration = c(201, 202, 203, 204)
  )
  manifest <- create_gazepoint_feature_manifest(
    features = "fixation_duration",
    scientific_source = "Gazepoint fixation export",
    source_table = "fixations",
    transformation = "Trial-level mean",
    availability_stage = "during_exposure",
    prediction_time_available = TRUE,
    preprocessing_scope = "none",
    fold_local_required = FALSE
  )

  expect_error(create_gazepoint_group_folds(
    data = data,
    outcome = "outcome",
    predictors = "fixation_duration",
    feature_manifest = manifest,
    generalization_target = "new_trials_known_participants",
    participant_id = "participant_id",
    trial_id = "trial_id",
    v = 3L
  ), "at least 3", fixed = TRUE)
})


test_that("print methods and CSV export work", {
  plan <- run_group_resampling("new_participants", repeats = 1L)

  expect_true(any(grepl(
    "Target: new_participants",
    capture.output(print(plan)),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "Overall status: PASS",
    capture.output(print(plan$validation)),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "Audited folds: 3",
    capture.output(print(plan$audit)),
    fixed = TRUE
  )))

  directory <- tempfile()
  on.exit(unlink(directory, recursive = TRUE, force = TRUE), add = TRUE)
  paths <- write_gazepoint_group_folds_csv(
    plan,
    directory,
    prefix = "test_folds",
    tables = c("assignments", "fold_summary"),
    include_fold_data = TRUE
  )

  expect_identical(length(paths), 2L + length(plan$folds) * 3L)
  expect_true(all(file.exists(paths)))
  expect_error(write_gazepoint_group_folds_csv(
    plan,
    directory,
    prefix = "test_folds",
    tables = c("assignments", "fold_summary"),
    include_fold_data = TRUE
  ), "already exist", fixed = TRUE)

  expect_error(write_gazepoint_group_folds_csv(
    plan,
    tempfile(),
    tables = "unknown"
  ), "tables", fixed = TRUE)
  expect_error(write_gazepoint_group_folds_csv(
    plan,
    tempfile(),
    prefix = "folder/name"
  ), "directory separators", fixed = TRUE)
})
