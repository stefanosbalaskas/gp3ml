make_resampling_diagnostics_data <- function(
    numeric_outcome = FALSE) {
  data <- expand.grid(
    participant_id = sprintf("P%02d", 1:6),
    trial_id = sprintf("T%02d", 1:3),
    stimulus_id = sprintf("S%02d", 1:4),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  trial_repetition <- data$trial_id
  data$trial_id <- paste(
    data$stimulus_id,
    trial_repetition,
    sep = "::"
  )

  participant_number <- as.integer(
    sub("P", "", data$participant_id)
  )
  stimulus_number <- as.integer(
    sub("S", "", data$stimulus_id)
  )

  if (numeric_outcome) {
    data$outcome <- seq_len(nrow(data)) / 10
  } else {
    data$outcome <- factor(
      ifelse(
        (participant_number + stimulus_number) %% 2L == 0L,
        "yes",
        "no"
      ),
      levels = c("no", "yes")
    )
  }

  data$fixation_duration <- 180 + seq_len(nrow(data))
  data$pupil_change <- round(
    sin(seq_len(nrow(data)) / 7),
    4
  )
  data
}


make_resampling_diagnostics_manifest <- function() {
  create_gazepoint_feature_manifest(
    features = c(
      "fixation_duration",
      "pupil_change"
    ),
    scientific_source = c(
      "Gazepoint fixation export",
      "Gazepoint pupil export"
    ),
    source_table = c(
      "fixations",
      "pupil"
    ),
    transformation = c(
      "Trial-level mean",
      "Trial-level change"
    ),
    availability_stage = c(
      "during_exposure",
      "during_exposure"
    ),
    prediction_time_available = c(
      TRUE,
      TRUE
    ),
    preprocessing_scope = c(
      "none",
      "none"
    ),
    fold_local_required = c(
      FALSE,
      FALSE
    )
  )
}


run_resampling_diagnostics_plan <- function(
    generalization_target = "new_participants",
    v = 3L,
    repeats = 2L,
    seed = 101L,
    numeric_outcome = FALSE) {
  create_gazepoint_group_folds(
    data = make_resampling_diagnostics_data(
      numeric_outcome = numeric_outcome
    ),
    outcome = "outcome",
    predictors = c(
      "fixation_duration",
      "pupil_change"
    ),
    feature_manifest = make_resampling_diagnostics_manifest(),
    generalization_target = generalization_target,
    participant_id = "participant_id",
    trial_id = "trial_id",
    stimulus_id = "stimulus_id",
    v = v,
    repeats = repeats,
    seed = seed
  )
}


test_that("categorical fold diagnostics expose all required tables", {
  plan <- run_resampling_diagnostics_plan()
  diagnostics <- diagnose_gazepoint_group_folds(plan)

  expect_s3_class(
    diagnostics,
    "gazepoint_fold_diagnostics"
  )
  expect_s3_class(
    diagnostics$validation,
    "gazepoint_fold_diagnostics_validation"
  )
  expect_identical(
    diagnostics$validation$status,
    "pass"
  )
  expect_identical(
    diagnostics$metadata$outcome_type,
    "categorical"
  )
  expect_identical(
    nrow(diagnostics$fold_metrics),
    length(plan$folds)
  )
  expect_identical(
    nrow(diagnostics$repeat_metrics),
    2L
  )
  expect_true(all(
    diagnostics$assessment_coverage$n_assessment == 1L
  ))
  expect_true(all(
    diagnostics$fold_metrics$n_total ==
      diagnostics$fold_metrics$n_analysis +
      diagnostics$fold_metrics$n_assessment +
      diagnostics$fold_metrics$n_excluded
  ))
  expect_true(all(c(
    "fold_metrics",
    "repeat_metrics",
    "outcome_balance",
    "group_balance",
    "assessment_coverage",
    "exclusion_summary",
    "metadata",
    "validation"
  ) %in% names(diagnostics)))
})


test_that("categorical outcome balance includes every assessment level", {
  diagnostics <- diagnose_gazepoint_group_folds(
    run_resampling_diagnostics_plan()
  )

  assessment <- diagnostics$outcome_balance[
    diagnostics$outcome_balance$partition == "assessment",
    ,
    drop = FALSE
  ]

  expect_true(all(
    assessment$metric_type == "categorical"
  ))
  expect_setequal(
    unique(assessment$outcome_level),
    c("no", "yes")
  )
  expect_true(all(assessment$n > 0L))
  expect_true(all(
    abs(
      stats::aggregate(
        assessment$proportion,
        by = list(assessment$fold_id),
        FUN = sum
      )$x - 1
    ) < 1e-12
  ))
})


test_that("continuous numeric outcomes receive numeric summaries", {
  plan <- run_resampling_diagnostics_plan(
    numeric_outcome = TRUE
  )
  diagnostics <- diagnose_gazepoint_group_folds(plan)

  expect_identical(
    diagnostics$metadata$outcome_type,
    "numeric"
  )
  expect_true(all(
    diagnostics$outcome_balance$metric_type == "numeric"
  ))
  expect_true(all(is.na(
    diagnostics$outcome_balance$outcome_level
  )))

  assessment <- diagnostics$outcome_balance[
    diagnostics$outcome_balance$partition == "assessment",
    ,
    drop = FALSE
  ]

  expect_true(all(assessment$n > 0L))
  expect_true(all(is.finite(assessment$mean)))
  expect_true(all(is.finite(assessment$median)))
  expect_identical(
    diagnostics$validation$checks$status[
      diagnostics$validation$checks$check_id ==
        "assessment_outcome_level_presence"
    ],
    "pass"
  )
})


test_that("crossed folds summarize excluded rows explicitly", {
  plan <- run_resampling_diagnostics_plan(
    generalization_target =
      "new_participants_and_new_stimuli",
    v = c(3L, 2L),
    repeats = 2L
  )
  diagnostics <- diagnose_gazepoint_group_folds(plan)

  expect_identical(
    nrow(diagnostics$fold_metrics),
    12L
  )
  expect_true(all(
    diagnostics$exclusion_summary$n_excluded > 0L
  ))
  expect_true(all(
    diagnostics$exclusion_summary$excluded_prop > 0
  ))
  expect_true(all(
    diagnostics$repeat_metrics$total_excluded > 0L
  ))
  expect_identical(
    diagnostics$validation$status,
    "pass"
  )
})


test_that("validation detects damaged assessment coverage", {
  diagnostics <- diagnose_gazepoint_group_folds(
    run_resampling_diagnostics_plan()
  )

  diagnostics$assessment_coverage$n_assessment[1L] <- 0L
  validation <- validate_gazepoint_fold_diagnostics(
    diagnostics
  )

  expect_identical(validation$status, "fail")
  expect_identical(
    validation$checks$status[
      validation$checks$check_id ==
        "assessment_coverage_once_per_repeat"
    ],
    "fail"
  )
  expect_true(any(
    validation$issues$check_id ==
      "assessment_coverage_once_per_repeat"
  ))
})


test_that("validation distinguishes review and fail imbalance thresholds", {
  diagnostics <- diagnose_gazepoint_group_folds(
    run_resampling_diagnostics_plan(),
    imbalance_review = 1.2,
    imbalance_fail = 2
  )

  diagnostics$repeat_metrics$assessment_size_ratio[1L] <- 1.5
  review <- validate_gazepoint_fold_diagnostics(
    diagnostics
  )

  expect_identical(review$status, "review")
  expect_identical(
    review$checks$status[
      review$checks$check_id ==
        "assessment_fold_size_balance"
    ],
    "review"
  )

  diagnostics$repeat_metrics$assessment_size_ratio[1L] <- 2.5
  failure <- validate_gazepoint_fold_diagnostics(
    diagnostics
  )

  expect_identical(failure$status, "fail")
  expect_identical(
    failure$checks$status[
      failure$checks$check_id ==
        "assessment_fold_size_balance"
    ],
    "fail"
  )
})


test_that("missing categorical assessment levels require review", {
  diagnostics <- diagnose_gazepoint_group_folds(
    run_resampling_diagnostics_plan()
  )

  target <- which(
    diagnostics$outcome_balance$partition == "assessment" &
      diagnostics$outcome_balance$outcome_level == "yes"
  )[[1L]]
  diagnostics$outcome_balance$n[target] <- 0L

  validation <- validate_gazepoint_fold_diagnostics(
    diagnostics
  )

  expect_identical(validation$status, "review")
  expect_identical(
    validation$checks$status[
      validation$checks$check_id ==
        "assessment_outcome_level_presence"
    ],
    "review"
  )
})


test_that("print methods and CSV export work", {
  diagnostics <- diagnose_gazepoint_group_folds(
    run_resampling_diagnostics_plan(
      repeats = 1L
    )
  )

  expect_true(any(grepl(
    "Target: new_participants",
    capture.output(print(diagnostics)),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "Diagnostic status: PASS",
    capture.output(print(diagnostics)),
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "Overall status: PASS",
    capture.output(print(diagnostics$validation)),
    fixed = TRUE
  )))

  directory <- tempfile()
  on.exit(
    unlink(
      directory,
      recursive = TRUE,
      force = TRUE
    ),
    add = TRUE
  )

  paths <- write_gazepoint_fold_diagnostics_csv(
    diagnostics,
    directory,
    prefix = "test_diagnostics"
  )

  expect_identical(length(paths), 8L)
  expect_true(all(file.exists(paths)))
  expect_error(
    write_gazepoint_fold_diagnostics_csv(
      diagnostics,
      directory,
      prefix = "test_diagnostics"
    ),
    "Refusing to overwrite",
    fixed = TRUE
  )

  overwrite_paths <- write_gazepoint_fold_diagnostics_csv(
    diagnostics,
    directory,
    prefix = "test_diagnostics",
    overwrite = TRUE
  )
  expect_identical(paths, overwrite_paths)
})


test_that("invalid inputs and thresholds are rejected", {
  plan <- run_resampling_diagnostics_plan()

  expect_error(
    diagnose_gazepoint_group_folds(data.frame()),
    "gazepoint_group_folds",
    fixed = TRUE
  )
  expect_error(
    diagnose_gazepoint_group_folds(
      plan,
      imbalance_review = 0.9
    ),
    "greater than or equal to 1",
    fixed = TRUE
  )
  expect_error(
    diagnose_gazepoint_group_folds(
      plan,
      imbalance_review = 2,
      imbalance_fail = 1.5
    ),
    "greater than or equal",
    fixed = TRUE
  )
  expect_error(
    validate_gazepoint_fold_diagnostics(plan),
    "gazepoint_fold_diagnostics",
    fixed = TRUE
  )
  expect_error(
    write_gazepoint_fold_diagnostics_csv(
      diagnose_gazepoint_group_folds(plan),
      tempfile(),
      tables = "unknown"
    ),
    "Unknown diagnostic tables",
    fixed = TRUE
  )
})

test_that("all generalization targets produce passing diagnostics", {
  targets <- list(
    new_trials_known_participants = 3L,
    new_participants = 3L,
    new_stimuli = 2L,
    new_participants_and_new_stimuli = c(3L, 2L)
  )

  plans <- lapply(
    names(targets),
    function(target) {
      run_resampling_diagnostics_plan(
        generalization_target = target,
        v = targets[[target]],
        repeats = 2L,
        seed = 2026L
      )
    }
  )
  names(plans) <- names(targets)

  diagnostics <- lapply(
    plans,
    diagnose_gazepoint_group_folds
  )

  expect_true(all(vapply(
    plans,
    function(x) x$validation$status == "pass",
    logical(1)
  )))
  expect_true(all(vapply(
    plans,
    function(x) x$audit$status == "pass",
    logical(1)
  )))
  expect_true(all(vapply(
    diagnostics,
    function(x) x$validation$status == "pass",
    logical(1)
  )))

  crossed <- diagnostics[[
    "new_participants_and_new_stimuli"
  ]]
  expect_gt(
    sum(crossed$exclusion_summary$n_excluded),
    0L
  )

  non_crossed <- diagnostics[
    setdiff(
      names(diagnostics),
      "new_participants_and_new_stimuli"
    )
  ]
  expect_true(all(vapply(
    non_crossed,
    function(x) {
      sum(x$exclusion_summary$n_excluded) == 0L
    },
    logical(1)
  )))
})
