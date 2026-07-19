make_group_split_data <- function() {
  data <- expand.grid(
    participant_id = sprintf("P%02d", 1:8),
    stimulus_id = sprintf("S%02d", 1:4),
    replicate = 1:2,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  data$trial_id <- paste0(
    data$stimulus_id,
    "_T",
    data$replicate
  )

  data$outcome <- as.integer(
    seq_len(nrow(data)) %% 2L
  )

  data$fixation_duration <- 200 +
    seq_len(nrow(data))

  data$pupil_change <- seq_len(nrow(data)) /
    100

  data$replicate <- NULL

  data
}


make_group_split_manifest <- function() {
  create_gazepoint_feature_manifest(
    features = c(
      "fixation_duration",
      "pupil_change"
    ),
    scientific_source = c(
      "Gazepoint fixation export",
      "Gazepoint all-gaze export"
    ),
    source_table = c(
      "fixations",
      "all_gaze"
    ),
    transformation = c(
      "Trial-level mean",
      "Baseline-adjusted change"
    ),
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


run_group_split <- function(
    generalization_target,
    seed = 17L) {
  split_gazepoint_ml_data(
    data = make_group_split_data(),
    outcome = "outcome",
    predictors = c(
      "fixation_duration",
      "pupil_change"
    ),
    feature_manifest =
      make_group_split_manifest(),
    generalization_target =
      generalization_target,
    participant_id = "participant_id",
    trial_id = "trial_id",
    stimulus_id = "stimulus_id",
    assessment_prop = 0.25,
    seed = seed
  )
}


test_that("new-participant splitting is deterministic", {
  split_a <- run_group_split(
    "new_participants",
    seed = 101L
  )

  split_b <- run_group_split(
    "new_participants",
    seed = 101L
  )

  expect_s3_class(
    split_a,
    "gazepoint_ml_split"
  )
  expect_identical(
    split_a$analysis_indices,
    split_b$analysis_indices
  )
  expect_identical(
    split_a$assessment_indices,
    split_b$assessment_indices
  )
  expect_identical(
    split_a$validation$status,
    "pass"
  )
})


test_that("new-participant groups are disjoint", {
  split <- run_group_split(
    "new_participants"
  )

  analysis_participants <- unique(
    split$analysis$participant_id
  )

  assessment_participants <- unique(
    split$assessment$participant_id
  )

  expect_length(
    intersect(
      analysis_participants,
      assessment_participants
    ),
    0L
  )

  expect_identical(
    nrow(split$excluded),
    0L
  )
})


test_that("new-stimulus groups are disjoint", {
  split <- run_group_split(
    "new_stimuli"
  )

  analysis_stimuli <- unique(
    split$analysis$stimulus_id
  )

  assessment_stimuli <- unique(
    split$assessment$stimulus_id
  )

  expect_length(
    intersect(
      analysis_stimuli,
      assessment_stimuli
    ),
    0L
  )

  expect_identical(
    split$validation$status,
    "pass"
  )
})


test_that("known participants occur in both trial partitions", {
  split <- run_group_split(
    "new_trials_known_participants"
  )

  analysis_participants <- sort(unique(
    split$analysis$participant_id
  ))

  assessment_participants <- sort(unique(
    split$assessment$participant_id
  ))

  expect_identical(
    analysis_participants,
    assessment_participants
  )

  expect_identical(
    analysis_participants,
    sort(unique(
      make_group_split_data()$participant_id
    ))
  )
})


test_that("participant-trial units remain intact", {
  split <- run_group_split(
    "new_trials_known_participants"
  )

  analysis_units <- paste(
    split$analysis$participant_id,
    split$analysis$trial_id,
    sep = "::"
  )

  assessment_units <- paste(
    split$assessment$participant_id,
    split$assessment$trial_id,
    sep = "::"
  )

  expect_length(
    intersect(
      unique(analysis_units),
      unique(assessment_units)
    ),
    0L
  )

  expect_identical(
    split$validation$status,
    "pass"
  )
})


test_that("trial labels may repeat across participants", {
  split <- run_group_split(
    "new_participants"
  )

  expect_true(
    length(intersect(
      unique(split$analysis$trial_id),
      unique(split$assessment$trial_id)
    )) > 0L
  )

  expect_identical(
    split$leakage_audit$status,
    "pass"
  )
})


test_that("simultaneous generalization creates strict blocks", {
  split <- run_group_split(
    "new_participants_and_new_stimuli"
  )

  expect_length(
    intersect(
      unique(split$analysis$participant_id),
      unique(split$assessment$participant_id)
    ),
    0L
  )

  expect_length(
    intersect(
      unique(split$analysis$stimulus_id),
      unique(split$assessment$stimulus_id)
    ),
    0L
  )

  expect_gt(
    nrow(split$excluded),
    0L
  )

  expect_identical(
    split$validation$status,
    "pass"
  )
})


test_that("all source rows are accounted for", {
  split <- run_group_split(
    "new_participants_and_new_stimuli"
  )

  observed <- sort(c(
    split$analysis$.gp3ml_source_row,
    split$assessment$.gp3ml_source_row,
    split$excluded$.gp3ml_source_row
  ))

  expect_identical(
    observed,
    seq_len(nrow(make_group_split_data()))
  )

  expect_identical(
    nrow(split$assignment),
    nrow(make_group_split_data())
  )
})


test_that("feature manifest is required and must pass", {
  data <- make_group_split_data()

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = "fixation_duration",
      feature_manifest = NULL,
      generalization_target =
        "new_participants",
      participant_id = "participant_id"
    ),
    "feature_manifest",
    fixed = TRUE
  )

  unsafe_manifest <- make_group_split_manifest()
  unsafe_manifest$outcome_derived[1] <- TRUE

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "fixation_duration",
        "pupil_change"
      ),
      feature_manifest = unsafe_manifest,
      generalization_target =
        "new_participants",
      participant_id = "participant_id"
    ),
    "must pass validation",
    fixed = TRUE
  )
})


test_that("required grouping identifiers are enforced", {
  data <- make_group_split_data()
  manifest <- make_group_split_manifest()

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "fixation_duration",
        "pupil_change"
      ),
      feature_manifest = manifest,
      generalization_target =
        "new_participants",
      participant_id = NULL
    ),
    "Required grouping identifiers",
    fixed = TRUE
  )

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "fixation_duration",
        "pupil_change"
      ),
      feature_manifest = manifest,
      generalization_target =
        "new_stimuli",
      stimulus_id = NULL
    ),
    "Required grouping identifiers",
    fixed = TRUE
  )
})


test_that("participants need at least two trial units", {
  data <- data.frame(
    participant_id = c("P01", "P02"),
    trial_id = c("T01", "T01"),
    outcome = c(0, 1),
    fixation_duration = c(210, 220)
  )

  manifest <- create_gazepoint_feature_manifest(
    features = "fixation_duration",
    scientific_source =
      "Gazepoint fixation export",
    source_table = "fixations",
    transformation = "Trial-level mean",
    availability_stage = "during_exposure",
    prediction_time_available = TRUE,
    preprocessing_scope = "none",
    fold_local_required = FALSE
  )

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = "fixation_duration",
      feature_manifest = manifest,
      generalization_target =
        "new_trials_known_participants",
      participant_id = "participant_id",
      trial_id = "trial_id"
    ),
    "fewer than two",
    fixed = TRUE
  )
})


test_that("split arguments are validated", {
  data <- make_group_split_data()
  manifest <- make_group_split_manifest()

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "fixation_duration",
        "pupil_change"
      ),
      feature_manifest = manifest,
      generalization_target =
        "new_participants",
      participant_id = "participant_id",
      assessment_prop = 1
    ),
    "strictly between",
    fixed = TRUE
  )

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "outcome",
        "fixation_duration"
      ),
      feature_manifest = manifest,
      generalization_target =
        "new_participants",
      participant_id = "participant_id"
    ),
    "must not be included",
    fixed = TRUE
  )

  expect_error(
    split_gazepoint_ml_data(
      data = data,
      outcome = "outcome",
      predictors = c(
        "participant_id",
        "fixation_duration"
      ),
      feature_manifest = manifest,
      generalization_target =
        "new_participants",
      participant_id = "participant_id"
    ),
    "Identifier columns",
    fixed = TRUE
  )
})


test_that("split validation detects source-row overlap", {
  split <- run_group_split(
    "new_participants"
  )

  split$assessment <- rbind(
    split$assessment,
    split$analysis[1, , drop = FALSE]
  )

  validation <- validate_gazepoint_ml_split(
    split
  )

  expect_identical(
    validation$status,
    "fail"
  )

  expect_identical(
    validation$checks$status[
      validation$checks$check_id ==
        "source_rows_disjoint"
    ],
    "fail"
  )
})


test_that("split print methods report key metadata", {
  split <- run_group_split(
    "new_participants"
  )

  split_output <- capture.output(
    print(split)
  )

  validation_output <- capture.output(
    print(split$validation)
  )

  expect_true(any(grepl(
    "Target: new_participants",
    split_output,
    fixed = TRUE
  )))

  expect_true(any(grepl(
    "Status: PASS",
    split_output,
    fixed = TRUE
  )))

  expect_true(any(grepl(
    "Overall status: PASS",
    validation_output,
    fixed = TRUE
  )))
})


test_that("split tables can be exported", {
  split <- run_group_split(
    "new_participants"
  )

  directory <- tempfile()
  on.exit(
    unlink(
      directory,
      recursive = TRUE
    ),
    add = TRUE
  )

  paths <- write_gazepoint_ml_split_csv(
    split,
    directory,
    prefix = "test_split"
  )

  expect_identical(
    length(paths),
    8L
  )

  expect_true(
    all(file.exists(paths))
  )

  exported_summary <- utils::read.csv(
    paths[["summary"]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_identical(
    nrow(exported_summary),
    1L
  )

  expect_identical(
    exported_summary$generalization_target,
    "new_participants"
  )

  expect_error(
    write_gazepoint_ml_split_csv(
      split,
      directory,
      prefix = "test_split"
    ),
    "already exist",
    fixed = TRUE
  )
})


test_that("CSV writer validates table requests", {
  split <- run_group_split(
    "new_participants"
  )

  expect_error(
    write_gazepoint_ml_split_csv(
      split,
      tempfile(),
      tables = "unknown_table"
    ),
    "tables",
    fixed = TRUE
  )

  expect_error(
    write_gazepoint_ml_split_csv(
      split,
      tempfile(),
      prefix = "folder/name"
    ),
    "directory separators",
    fixed = TRUE
  )
})
