.gp3ml_resample_integer <- function(x, argument, minimum = 1L) {
  if (
    !is.numeric(x) || length(x) == 0L || anyNA(x) ||
      any(!is.finite(x)) || any(x != as.integer(x)) ||
      any(x < minimum)
  ) {
    stop(
      sprintf(
        "`%s` must contain finite integers greater than or equal to %d.",
        argument,
        minimum
      ),
      call. = FALSE
    )
  }

  as.integer(x)
}


.gp3ml_resample_v <- function(v, generalization_target) {
  v <- .gp3ml_resample_integer(v, "v", minimum = 2L)

  if (identical(
    generalization_target,
    "new_participants_and_new_stimuli"
  )) {
    if (!(length(v) %in% c(1L, 2L))) {
      stop(
        paste0(
          "For simultaneous participant and stimulus generalization, ",
          "`v` must have length one or two."
        ),
        call. = FALSE
      )
    }

    if (length(v) == 1L) {
      v <- rep(v, 2L)
    }

    names(v) <- c("participant", "stimulus")
    return(v)
  }

  if (length(v) != 1L) {
    stop(
      "`v` must be a single integer for this generalization target.",
      call. = FALSE
    )
  }

  names(v) <- "group"
  v
}


.gp3ml_resample_assign_groups <- function(values, v) {
  values <- as.character(values)
  groups <- sort(unique(values))

  if (length(groups) < v) {
    stop(
      sprintf(
        "At least %d distinct groups are required; only %d were found.",
        v,
        length(groups)
      ),
      call. = FALSE
    )
  }

  group_index <- match(values, groups)
  group_sizes <- tabulate(group_index, nbins = length(groups))
  random_ties <- sample.int(length(groups), length(groups))
  assignment_order <- order(-group_sizes, random_ties)

  fold_rows <- integer(v)
  fold_groups <- integer(v)
  group_fold <- integer(length(groups))

  for (group_position in assignment_order) {
    candidates <- which(fold_rows == min(fold_rows))
    candidates <- candidates[
      fold_groups[candidates] == min(fold_groups[candidates])
    ]

    selected <- if (length(candidates) == 1L) {
      candidates
    } else {
      sample(candidates, 1L)
    }

    group_fold[group_position] <- selected
    fold_rows[selected] <- fold_rows[selected] + group_sizes[group_position]
    fold_groups[selected] <- fold_groups[selected] + 1L
  }

  list(
    row_fold = group_fold[group_index],
    mapping = data.frame(
      group = groups,
      fold = group_fold,
      n_rows = group_sizes,
      stringsAsFactors = FALSE
    )
  )
}


.gp3ml_resample_bind <- function(rows) {
  if (length(rows) == 0L) {
    return(data.frame())
  }

  result <- do.call(rbind, rows)
  row.names(result) <- NULL
  result
}


.gp3ml_resample_overall_status <- function(status) {
  if (any(status == "fail")) {
    return("fail")
  }

  if (any(status == "review")) {
    return("review")
  }

  "pass"
}


.gp3ml_resample_fold_id <- function(
    repeat_id,
    fold_id,
    participant_fold = NA_integer_,
    stimulus_fold = NA_integer_) {
  if (!is.na(participant_fold) && !is.na(stimulus_fold)) {
    return(sprintf(
      "Repeat%02d_P%02d_S%02d",
      repeat_id,
      participant_fold,
      stimulus_fold
    ))
  }

  sprintf("Repeat%02d_Fold%02d", repeat_id, fold_id)
}


#' Create deterministic group-aware Gazepoint resampling folds
#'
#' Creates repeated grouped assessment folds that preserve the grouping
#' structure implied by an explicit generalization target. A passing
#' feature-provenance manifest is required, and every analysis-assessment
#' pair is evaluated using the leakage audit.
#'
#' @param data A data frame containing the outcome, predictors, and grouping
#'   identifiers.
#' @param outcome Name of the outcome column.
#' @param predictors Character vector naming intended predictors.
#' @param feature_manifest A feature manifest containing all intended
#'   predictors.
#' @param generalization_target One of `"new_trials_known_participants"`,
#'   `"new_participants"`, `"new_stimuli"`, or
#'   `"new_participants_and_new_stimuli"`.
#' @param participant_id Optional participant-identifier column.
#' @param trial_id Optional trial-identifier column.
#' @param stimulus_id Optional stimulus-identifier column.
#' @param v Number of group folds. For simultaneous participant and stimulus
#'   generalization, a length-two vector specifies participant and stimulus
#'   fold counts.
#' @param repeats Number of repeated fold assignments.
#' @param seed Integer random seed. The caller's random-number state is
#'   restored.
#' @param source_row_id Name of the source-row identifier added to returned
#'   partitions.
#'
#' @return An object of class `gazepoint_group_folds`.
#'
#' @details
#' For new trials among known participants, participant-trial units are
#' assigned separately within each participant. For simultaneous participant
#' and stimulus generalization, crossed participant-stimulus assessment blocks
#' are created; cross-block rows are excluded from that fold. Each source row
#' appears in assessment exactly once per repeat.
#'
#' This function does not perform preprocessing, feature selection, tuning,
#' nested resampling, or model fitting.
#'
#' @export
create_gazepoint_group_folds <- function(
    data,
    outcome,
    predictors,
    feature_manifest,
    generalization_target,
    participant_id = NULL,
    trial_id = NULL,
    stimulus_id = NULL,
    v = 5L,
    repeats = 1L,
    seed = 1L,
    source_row_id = ".gp3ml_source_row") {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (nrow(data) < 2L) {
    stop("`data` must contain at least two rows.", call. = FALSE)
  }

  outcome <- .gp3ml_split_scalar_column(
    outcome,
    "outcome",
    allow_null = FALSE
  )
  source_row_id <- .gp3ml_split_scalar_column(
    source_row_id,
    "source_row_id",
    allow_null = FALSE
  )
  participant_id <- .gp3ml_split_scalar_column(
    participant_id,
    "participant_id"
  )
  trial_id <- .gp3ml_split_scalar_column(trial_id, "trial_id")
  stimulus_id <- .gp3ml_split_scalar_column(stimulus_id, "stimulus_id")

  if (
    !is.character(predictors) || length(predictors) == 0L ||
      anyNA(predictors) || any(!nzchar(trimws(predictors)))
  ) {
    stop(
      "`predictors` must contain non-empty column names.",
      call. = FALSE
    )
  }

  predictors <- trimws(predictors)

  if (anyDuplicated(predictors)) {
    stop("`predictors` must contain unique column names.", call. = FALSE)
  }

  if (outcome %in% predictors) {
    stop("`outcome` must not be included in `predictors`.", call. = FALSE)
  }

  identifier_predictors <- intersect(
    predictors,
    c(participant_id, trial_id, stimulus_id, source_row_id)
  )

  if (length(identifier_predictors) > 0L) {
    stop(
      sprintf(
        "Identifier columns must not be predictors: %s.",
        paste(identifier_predictors, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  targets <- .gp3ml_split_targets()

  if (
    !is.character(generalization_target) ||
      length(generalization_target) != 1L ||
      is.na(generalization_target) ||
      !(generalization_target %in% targets)
  ) {
    stop(
      sprintf(
        "`generalization_target` must be one of: %s.",
        paste(targets, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  v <- .gp3ml_resample_v(v, generalization_target)
  repeats <- .gp3ml_resample_integer(repeats, "repeats", minimum = 1L)
  seed <- .gp3ml_resample_integer(seed, "seed", minimum = 0L)

  if (length(repeats) != 1L) {
    stop("`repeats` must be a single integer.", call. = FALSE)
  }

  if (length(seed) != 1L) {
    stop("`seed` must be a single integer.", call. = FALSE)
  }

  identifiers_ok <- switch(
    generalization_target,
    new_trials_known_participants =
      !is.null(participant_id) && !is.null(trial_id),
    new_participants = !is.null(participant_id),
    new_stimuli = !is.null(stimulus_id),
    new_participants_and_new_stimuli =
      !is.null(participant_id) && !is.null(stimulus_id)
  )

  if (!identifiers_ok) {
    stop(
      sprintf(
        paste0(
          "Required grouping identifiers were not supplied for ",
          "`generalization_target = \\\"%s\\\"`."
        ),
        generalization_target
      ),
      call. = FALSE
    )
  }

  if (source_row_id %in% names(data)) {
    stop(
      sprintf(
        "`data` already contains the reserved source-row column `%s`.",
        source_row_id
      ),
      call. = FALSE
    )
  }

  .gp3ml_split_require_columns(
    data,
    c(outcome, predictors, participant_id, trial_id, stimulus_id)
  )

  manifest_result <- .gp3ml_split_manifest(feature_manifest, predictors)

  participant <- if (!is.null(participant_id)) {
    .gp3ml_split_group_values(data, participant_id, "participant_id")
  } else {
    NULL
  }

  trial <- if (!is.null(trial_id)) {
    .gp3ml_split_group_values(data, trial_id, "trial_id")
  } else {
    NULL
  }

  stimulus <- if (!is.null(stimulus_id)) {
    .gp3ml_split_group_values(data, stimulus_id, "stimulus_id")
  } else {
    NULL
  }

  if (
    identical(generalization_target, "new_participants") &&
      length(unique(participant)) < v[[1L]]
  ) {
    stop("`v` exceeds the number of distinct participants.", call. = FALSE)
  }

  if (
    identical(generalization_target, "new_stimuli") &&
      length(unique(stimulus)) < v[[1L]]
  ) {
    stop("`v` exceeds the number of distinct stimuli.", call. = FALSE)
  }

  if (identical(
    generalization_target,
    "new_participants_and_new_stimuli"
  )) {
    if (length(unique(participant)) < v[["participant"]]) {
      stop(
        "Participant `v` exceeds the number of distinct participants.",
        call. = FALSE
      )
    }

    if (length(unique(stimulus)) < v[["stimulus"]]) {
      stop(
        "Stimulus `v` exceeds the number of distinct stimuli.",
        call. = FALSE
      )
    }
  }

  trial_units <- if (identical(
    generalization_target,
    "new_trials_known_participants"
  )) {
    .gp3ml_split_trial_units(participant, trial)
  } else {
    NULL
  }

  if (!is.null(trial_units)) {
    trial_counts <- vapply(
      split(trial_units, participant),
      function(values) length(unique(values)),
      integer(1)
    )

    insufficient <- names(trial_counts)[trial_counts < v[[1L]]]

    if (length(insufficient) > 0L) {
      stop(
        sprintf(
          paste0(
            "Each participant must have at least %d distinct ",
            "participant-trial units. Insufficient participants: %s."
          ),
          v[[1L]],
          paste(insufficient, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  had_seed <- exists(
    ".Random.seed",
    envir = .GlobalEnv,
    inherits = FALSE
  )
  previous_seed <- if (had_seed) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }

  on.exit(
    .gp3ml_split_restore_rng(had_seed, previous_seed),
    add = TRUE
  )

  set.seed(seed)

  source_rows <- seq_len(nrow(data))
  fold_data <- data
  fold_data[[source_row_id]] <- source_rows

  folds <- list()
  assignment_rows <- list()
  summary_rows <- list()
  group_count_rows <- list()
  mapping_rows <- list()

  folds_per_repeat <- if (identical(
    generalization_target,
    "new_participants_and_new_stimuli"
  )) {
    prod(v)
  } else {
    v[[1L]]
  }

  for (repeat_index in seq_len(repeats)) {
    group_fold <- rep(NA_integer_, nrow(data))
    participant_fold <- rep(NA_integer_, nrow(data))
    stimulus_fold <- rep(NA_integer_, nrow(data))
    split_unit <- rep(NA_character_, nrow(data))

    if (identical(generalization_target, "new_participants")) {
      assigned <- .gp3ml_resample_assign_groups(participant, v[[1L]])
      group_fold <- assigned$row_fold
      participant_fold <- assigned$row_fold
      split_unit <- participant

      mapping <- assigned$mapping
      mapping[["repeat"]] <- repeat_index
      mapping$unit <- "participant"
      mapping_rows[[length(mapping_rows) + 1L]] <- mapping[
        , c("repeat", "unit", "group", "fold", "n_rows"), drop = FALSE
      ]
    } else if (identical(generalization_target, "new_stimuli")) {
      assigned <- .gp3ml_resample_assign_groups(stimulus, v[[1L]])
      group_fold <- assigned$row_fold
      stimulus_fold <- assigned$row_fold
      split_unit <- stimulus

      mapping <- assigned$mapping
      mapping[["repeat"]] <- repeat_index
      mapping$unit <- "stimulus"
      mapping_rows[[length(mapping_rows) + 1L]] <- mapping[
        , c("repeat", "unit", "group", "fold", "n_rows"), drop = FALSE
      ]
    } else if (identical(
      generalization_target,
      "new_trials_known_participants"
    )) {
      split_unit <- trial_units

      for (participant_value in sort(unique(participant))) {
        selected <- participant == participant_value
        assigned <- .gp3ml_resample_assign_groups(
          trial_units[selected],
          v[[1L]]
        )
        group_fold[selected] <- assigned$row_fold

        mapping <- assigned$mapping
        mapping[["repeat"]] <- repeat_index
        mapping$unit <- "participant_trial"
        mapping$participant <- participant_value
        mapping_rows[[length(mapping_rows) + 1L]] <- mapping[
          , c(
            "repeat", "unit", "participant", "group", "fold", "n_rows"
          ),
          drop = FALSE
        ]
      }
    } else {
      participant_assignment <- .gp3ml_resample_assign_groups(
        participant,
        v[["participant"]]
      )
      stimulus_assignment <- .gp3ml_resample_assign_groups(
        stimulus,
        v[["stimulus"]]
      )

      participant_fold <- participant_assignment$row_fold
      stimulus_fold <- stimulus_assignment$row_fold
      split_unit <- paste0(
        nchar(participant),
        ":",
        participant,
        "|",
        nchar(stimulus),
        ":",
        stimulus
      )

      participant_mapping <- participant_assignment$mapping
      participant_mapping[["repeat"]] <- repeat_index
      participant_mapping$unit <- "participant"
      mapping_rows[[length(mapping_rows) + 1L]] <- participant_mapping[
        , c("repeat", "unit", "group", "fold", "n_rows"), drop = FALSE
      ]

      stimulus_mapping <- stimulus_assignment$mapping
      stimulus_mapping[["repeat"]] <- repeat_index
      stimulus_mapping$unit <- "stimulus"
      mapping_rows[[length(mapping_rows) + 1L]] <- stimulus_mapping[
        , c("repeat", "unit", "group", "fold", "n_rows"), drop = FALSE
      ]
    }

    fold_specification <- if (identical(
      generalization_target,
      "new_participants_and_new_stimuli"
    )) {
      expand.grid(
        participant_fold = seq_len(v[["participant"]]),
        stimulus_fold = seq_len(v[["stimulus"]]),
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        group_fold = seq_len(v[[1L]]),
        stringsAsFactors = FALSE
      )
    }

    for (fold_index in seq_len(nrow(fold_specification))) {
      if (identical(
        generalization_target,
        "new_participants_and_new_stimuli"
      )) {
        held_participant_fold <- fold_specification$participant_fold[
          fold_index
        ]
        held_stimulus_fold <- fold_specification$stimulus_fold[
          fold_index
        ]
        participant_held <- participant_fold == held_participant_fold
        stimulus_held <- stimulus_fold == held_stimulus_fold

        partition <- ifelse(
          participant_held & stimulus_held,
          "assessment",
          ifelse(
            !participant_held & !stimulus_held,
            "analysis",
            "excluded"
          )
        )
      } else {
        held_group_fold <- fold_specification$group_fold[fold_index]
        partition <- ifelse(
          group_fold == held_group_fold,
          "assessment",
          "analysis"
        )
        held_participant_fold <- if (identical(
          generalization_target,
          "new_participants"
        )) {
          held_group_fold
        } else {
          NA_integer_
        }
        held_stimulus_fold <- if (identical(
          generalization_target,
          "new_stimuli"
        )) {
          held_group_fold
        } else {
          NA_integer_
        }
      }

      fold_identifier <- .gp3ml_resample_fold_id(
        repeat_index,
        fold_index,
        held_participant_fold,
        held_stimulus_fold
      )

      analysis_indices <- source_rows[partition == "analysis"]
      assessment_indices <- source_rows[partition == "assessment"]
      excluded_indices <- source_rows[partition == "excluded"]

      if (
        length(analysis_indices) == 0L ||
          length(assessment_indices) == 0L
      ) {
        stop(
          sprintf(
            "Fold `%s` produced an empty analysis or assessment partition.",
            fold_identifier
          ),
          call. = FALSE
        )
      }

      analysis <- fold_data[analysis_indices, , drop = FALSE]
      assessment <- fold_data[assessment_indices, , drop = FALSE]
      excluded <- fold_data[excluded_indices, , drop = FALSE]
      row.names(analysis) <- NULL
      row.names(assessment) <- NULL
      row.names(excluded) <- NULL

      leakage_audit <- audit_gazepoint_ml_leakage(
        analysis = analysis,
        assessment = assessment,
        outcome = outcome,
        predictors = predictors,
        participant_id = participant_id,
        trial_id = trial_id,
        stimulus_id = stimulus_id,
        generalization_target = generalization_target
      )

      folds[[fold_identifier]] <- structure(
        list(
          `repeat` = repeat_index,
          fold = fold_index,
          fold_id = fold_identifier,
          participant_fold = held_participant_fold,
          stimulus_fold = held_stimulus_fold,
          analysis = analysis,
          assessment = assessment,
          excluded = excluded,
          analysis_indices = analysis_indices,
          assessment_indices = assessment_indices,
          excluded_indices = excluded_indices,
          leakage_audit = leakage_audit
        ),
        class = "gazepoint_group_fold"
      )

      assignment_rows[[length(assignment_rows) + 1L]] <- data.frame(
        check.names = FALSE,
        `repeat` = repeat_index,
        fold = fold_index,
        fold_id = fold_identifier,
        source_row = source_rows,
        partition = partition,
        split_unit = split_unit,
        group_fold = group_fold,
        participant_fold = participant_fold,
        stimulus_fold = stimulus_fold,
        stringsAsFactors = FALSE
      )

      summary_rows[[length(summary_rows) + 1L]] <- data.frame(
        check.names = FALSE,
        `repeat` = repeat_index,
        fold = fold_index,
        fold_id = fold_identifier,
        participant_fold = held_participant_fold,
        stimulus_fold = held_stimulus_fold,
        n_total = nrow(data),
        n_analysis = length(analysis_indices),
        n_assessment = length(assessment_indices),
        n_excluded = length(excluded_indices),
        assessment_prop_all = length(assessment_indices) / nrow(data),
        assessment_prop_retained = length(assessment_indices) /
          (length(analysis_indices) + length(assessment_indices)),
        leakage_status = leakage_audit$status,
        stringsAsFactors = FALSE
      )

      counts <- .gp3ml_split_group_counts(
        data,
        partition,
        participant_id,
        trial_id,
        stimulus_id
      )
      counts[["repeat"]] <- repeat_index
      counts$fold <- fold_index
      counts$fold_id <- fold_identifier
      group_count_rows[[length(group_count_rows) + 1L]] <- counts[
        , c(
          "repeat", "fold", "fold_id", "partition", "unit", "n_groups"
        ),
        drop = FALSE
      ]
    }
  }

  result <- structure(
    list(
      folds = folds,
      assignments = .gp3ml_resample_bind(assignment_rows),
      fold_summary = .gp3ml_resample_bind(summary_rows),
      group_counts = .gp3ml_resample_bind(group_count_rows),
      group_mapping = .gp3ml_resample_bind(mapping_rows),
      feature_manifest = manifest_result$manifest,
      feature_manifest_validation = manifest_result$validation,
      metadata = list(
        outcome = outcome,
        predictors = predictors,
        participant_id = participant_id,
        trial_id = trial_id,
        stimulus_id = stimulus_id,
        generalization_target = generalization_target,
        v = v,
        repeats = repeats,
        seed = seed,
        source_row_id = source_row_id,
        n_source_rows = nrow(data),
        n_folds_per_repeat = folds_per_repeat,
        n_folds_total = folds_per_repeat * repeats
      ),
      call = match.call()
    ),
    class = "gazepoint_group_folds"
  )

  result$metadata$n_folds_per_repeat <- as.integer(
    result$metadata$n_folds_per_repeat
  )

  result$metadata$n_folds_total <- as.integer(
    result$metadata$n_folds_total
  )

  result$audit <- audit_gazepoint_group_folds(result)
  result$validation <- validate_gazepoint_group_folds(result)
  result
}


#' Aggregate leakage audits across group-aware folds
#'
#' @param x A `gazepoint_group_folds` object.
#'
#' @return An object of class `gazepoint_group_folds_audit`.
#'
#' @export
audit_gazepoint_group_folds <- function(x) {
  if (!inherits(x, "gazepoint_group_folds")) {
    stop("`x` must be a `gazepoint_group_folds` object.", call. = FALSE)
  }

  if (!is.list(x$folds) || length(x$folds) == 0L) {
    stop("`x` does not contain fold audit results.", call. = FALSE)
  }

  summary_rows <- list()
  check_rows <- list()

  for (fold_object in x$folds) {
    audit <- fold_object$leakage_audit

    if (
      is.null(audit) || is.null(audit$status) ||
        !is.data.frame(audit$checks)
    ) {
      stop(
        sprintf(
          "Fold `%s` does not contain a compatible leakage audit.",
          fold_object$fold_id
        ),
        call. = FALSE
      )
    }

    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      check.names = FALSE,
      `repeat` = fold_object[["repeat"]],
      fold = fold_object$fold,
      fold_id = fold_object$fold_id,
      status = audit$status,
      n_pass = sum(audit$checks$status == "pass"),
      n_review = sum(audit$checks$status == "review"),
      n_fail = sum(audit$checks$status == "fail"),
      stringsAsFactors = FALSE
    )

    checks <- audit$checks
    checks[["repeat"]] <- fold_object[["repeat"]]
    checks$fold <- fold_object$fold
    checks$fold_id <- fold_object$fold_id
    check_rows[[length(check_rows) + 1L]] <- checks[
      , c(
        "repeat",
        "fold",
        "fold_id",
        setdiff(names(checks), c("repeat", "fold", "fold_id"))
      ),
      drop = FALSE
    ]
  }

  summary <- .gp3ml_resample_bind(summary_rows)
  checks <- .gp3ml_resample_bind(check_rows)
  issues <- checks[checks$status != "pass", , drop = FALSE]
  row.names(issues) <- NULL

  structure(
    list(
      status = .gp3ml_resample_overall_status(summary$status),
      summary = summary,
      checks = checks,
      issues = issues,
      call = match.call()
    ),
    class = "gazepoint_group_folds_audit"
  )
}


#' Validate group-aware Gazepoint resampling folds
#'
#' @param x A `gazepoint_group_folds` object.
#'
#' @return An object of class `gazepoint_group_folds_validation`.
#'
#' @export
validate_gazepoint_group_folds <- function(x) {
  if (!inherits(x, "gazepoint_group_folds")) {
    stop("`x` must be a `gazepoint_group_folds` object.", call. = FALSE)
  }

  required <- c(
    "folds",
    "assignments",
    "fold_summary",
    "group_counts",
    "group_mapping",
    "feature_manifest_validation",
    "audit",
    "metadata"
  )
  missing_components <- setdiff(required, names(x))

  if (length(missing_components) > 0L) {
    stop(
      sprintf(
        "Fold object is missing components: %s.",
        paste(missing_components, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  checks <- list()
  add_check <- function(check_id, status, message, remediation) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check_id = check_id,
      status = status,
      message = message,
      remediation = remediation,
      stringsAsFactors = FALSE
    )
  }

  expected_fold_count <- x$metadata$n_folds_total
  observed_fold_count <- length(x$folds)
  fold_count_ok <- identical(
    as.integer(observed_fold_count),
    as.integer(expected_fold_count)
  )
  add_check(
    "fold_count",
    if (fold_count_ok) "pass" else "fail",
    sprintf(
      "Expected %d folds and found %d.",
      expected_fold_count,
      observed_fold_count
    ),
    if (fold_count_ok) "None." else "Recreate the fold plan."
  )

  fold_ids <- vapply(x$folds, `[[`, character(1), "fold_id")
  ids_ok <- !anyDuplicated(fold_ids) && !anyNA(fold_ids) &&
    all(nzchar(fold_ids))
  add_check(
    "fold_ids_unique",
    if (ids_ok) "pass" else "fail",
    if (ids_ok) {
      "Fold identifiers are unique and non-empty."
    } else {
      "Fold identifiers are duplicated or invalid."
    },
    if (ids_ok) "None." else "Recreate fold identifiers."
  )

  valid_partitions <- c("analysis", "assessment", "excluded")
  partitions_ok <- is.data.frame(x$assignments) &&
    nrow(x$assignments) > 0L &&
    all(x$assignments$partition %in% valid_partitions)
  add_check(
    "assignment_partitions_valid",
    if (partitions_ok) "pass" else "fail",
    if (partitions_ok) {
      "Assignment partitions use valid labels."
    } else {
      "Assignment partitions contain invalid labels."
    },
    if (partitions_ok) "None." else "Recreate the assignment table."
  )

  assignment_key <- interaction(
    x$assignments[["repeat"]],
    x$assignments$fold,
    drop = TRUE,
    lex.order = TRUE
  )
  assignment_groups <- split(x$assignments, assignment_key)
  expected_rows <- seq_len(x$metadata$n_source_rows)
  accounting_ok <- length(assignment_groups) == expected_fold_count &&
    all(vapply(
      assignment_groups,
      function(assignments) {
        identical(sort(assignments$source_row), expected_rows) &&
          !anyDuplicated(assignments$source_row)
      },
      logical(1)
    ))
  add_check(
    "source_rows_accounted_per_fold",
    if (accounting_ok) "pass" else "fail",
    if (accounting_ok) {
      "Every fold accounts for each source row exactly once."
    } else {
      "Source-row accounting is incomplete or duplicated."
    },
    if (accounting_ok) {
      "None."
    } else {
      "Reconstruct fold assignments from the source data."
    }
  )

  non_empty_ok <- all(vapply(
    x$folds,
    function(fold_object) {
      nrow(fold_object$analysis) > 0L &&
        nrow(fold_object$assessment) > 0L
    },
    logical(1)
  ))
  add_check(
    "analysis_assessment_non_empty",
    if (non_empty_ok) "pass" else "fail",
    if (non_empty_ok) {
      "All folds have non-empty analysis and assessment partitions."
    } else {
      "At least one fold has an empty analysis or assessment partition."
    },
    if (non_empty_ok) "None." else "Reduce `v` or revise grouping."
  )

  target <- x$metadata$generalization_target
  excluded_ok <- identical(
    target,
    "new_participants_and_new_stimuli"
  ) || all(x$assignments$partition != "excluded")
  add_check(
    "excluded_rows_compatible",
    if (excluded_ok) "pass" else "fail",
    if (excluded_ok) {
      "Excluded rows are compatible with the generalization target."
    } else {
      "Unexpected excluded rows were found."
    },
    if (excluded_ok) "None." else "Recreate folds using the target."
  )

  assessment_counts <- stats::aggregate(
    as.integer(x$assignments$partition == "assessment"),
    by = list(
      `repeat` = x$assignments[["repeat"]],
      source_row = x$assignments$source_row
    ),
    FUN = sum
  )
  names(assessment_counts)[3L] <- "n_assessment"
  coverage_ok <- nrow(assessment_counts) ==
    x$metadata$repeats * x$metadata$n_source_rows &&
    all(assessment_counts$n_assessment == 1L)
  add_check(
    "assessment_coverage_once_per_repeat",
    if (coverage_ok) "pass" else "fail",
    if (coverage_ok) {
      "Every source row appears in assessment exactly once per repeat."
    } else {
      "Assessment coverage is incomplete or duplicated."
    },
    if (coverage_ok) "None." else "Recreate the fold assignments."
  )

  materialized_ok <- all(vapply(
    x$folds,
    function(fold_object) {
      assignments <- x$assignments[
        x$assignments[["repeat"]] == fold_object[["repeat"]] &
          x$assignments$fold == fold_object$fold,
        ,
        drop = FALSE
      ]

      identical(
        sort(assignments$source_row[assignments$partition == "analysis"]),
        sort(fold_object$analysis_indices)
      ) && identical(
        sort(assignments$source_row[assignments$partition == "assessment"]),
        sort(fold_object$assessment_indices)
      ) && identical(
        sort(assignments$source_row[assignments$partition == "excluded"]),
        sort(fold_object$excluded_indices)
      )
    },
    logical(1)
  ))
  add_check(
    "materialized_partitions_match_assignments",
    if (materialized_ok) "pass" else "fail",
    if (materialized_ok) {
      "Materialized partitions match the assignment table."
    } else {
      "Materialized partitions and assignments disagree."
    },
    if (materialized_ok) "None." else "Recreate the fold object."
  )

  manifest_status <- x$feature_manifest_validation$status
  add_check(
    "feature_manifest_passed",
    manifest_status,
    sprintf("Feature-manifest validation status is `%s`.", manifest_status),
    if (identical(manifest_status, "pass")) {
      "None."
    } else {
      "Resolve feature-provenance issues."
    }
  )

  audit_status <- x$audit$status
  add_check(
    "fold_leakage_audit",
    audit_status,
    sprintf("Aggregated fold leakage-audit status is `%s`.", audit_status),
    if (identical(audit_status, "pass")) {
      "None."
    } else {
      "Review the fold-level leakage-audit issues."
    }
  )

  checks <- .gp3ml_resample_bind(checks)
  issues <- checks[checks$status != "pass", , drop = FALSE]
  row.names(issues) <- NULL
  levels <- c("pass", "review", "fail")
  summary <- data.frame(
    status = levels,
    n_checks = vapply(
      levels,
      function(status) sum(checks$status == status),
      integer(1)
    ),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      status = .gp3ml_resample_overall_status(checks$status),
      summary = summary,
      checks = checks,
      issues = issues,
      assessment_coverage = assessment_counts,
      call = match.call()
    ),
    class = "gazepoint_group_folds_validation"
  )
}


#' Print group-aware Gazepoint resampling folds
#'
#' @param x A `gazepoint_group_folds` object.
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_group_folds <- function(x, ...) {
  cat("<gazepoint_group_folds>\n")
  cat("Target: ", x$metadata$generalization_target, "\n", sep = "")
  cat("Repeats: ", x$metadata$repeats, "\n", sep = "")
  cat(
    "Folds per repeat: ",
    x$metadata$n_folds_per_repeat,
    "\n",
    sep = ""
  )
  cat("Total folds: ", x$metadata$n_folds_total, "\n", sep = "")
  cat("Status: ", toupper(x$validation$status), "\n", sep = "")
  invisible(x)
}


#' Print group-aware fold validation
#'
#' @param x A `gazepoint_group_folds_validation` object.
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_group_folds_validation <- function(x, ...) {
  cat("<gazepoint_group_folds_validation>\n")
  cat("Overall status: ", toupper(x$status), "\n", sep = "")
  cat("Non-passing checks: ", nrow(x$issues), "\n", sep = "")
  print(x$summary, row.names = FALSE, right = FALSE)
  invisible(x)
}


#' Print aggregated group-fold leakage auditing
#'
#' @param x A `gazepoint_group_folds_audit` object.
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_group_folds_audit <- function(x, ...) {
  cat("<gazepoint_group_folds_audit>\n")
  cat("Overall status: ", toupper(x$status), "\n", sep = "")
  cat("Audited folds: ", nrow(x$summary), "\n", sep = "")
  cat("Non-passing checks: ", nrow(x$issues), "\n", sep = "")
  invisible(x)
}


#' Write group-aware resampling tables to CSV
#'
#' @param x A `gazepoint_group_folds` object.
#' @param directory Output directory.
#' @param prefix Non-empty filename prefix.
#' @param tables Character vector selecting summary tables.
#' @param include_fold_data Logical. Whether every materialized fold partition
#'   should also be written.
#' @param overwrite Logical. Whether existing files may be replaced.
#' @param na Character representation of missing values.
#'
#' @return A named character vector of normalized output paths, invisibly.
#'
#' @export
write_gazepoint_group_folds_csv <- function(
    x,
    directory,
    prefix = "gazepoint_group_folds",
    tables = c(
      "assignments",
      "fold_summary",
      "group_counts",
      "group_mapping",
      "validation_checks",
      "validation_issues",
      "audit_summary",
      "audit_checks",
      "audit_issues"
    ),
    include_fold_data = FALSE,
    overwrite = FALSE,
    na = "") {
  if (!inherits(x, "gazepoint_group_folds")) {
    stop("`x` must be a `gazepoint_group_folds` object.", call. = FALSE)
  }

  if (
    !is.character(directory) || length(directory) != 1L ||
      is.na(directory) || !nzchar(trimws(directory))
  ) {
    stop("`directory` must be a single non-empty path.", call. = FALSE)
  }

  if (
    !is.character(prefix) || length(prefix) != 1L ||
      is.na(prefix) || !nzchar(trimws(prefix))
  ) {
    stop("`prefix` must be a single non-empty string.", call. = FALSE)
  }

  if (grepl("[/\\\\]", prefix)) {
    stop("`prefix` must not contain directory separators.", call. = FALSE)
  }

  valid_tables <- c(
    "assignments",
    "fold_summary",
    "group_counts",
    "group_mapping",
    "validation_checks",
    "validation_issues",
    "audit_summary",
    "audit_checks",
    "audit_issues"
  )

  if (
    !is.character(tables) || length(tables) == 0L || anyNA(tables) ||
      any(!(tables %in% valid_tables))
  ) {
    stop(
      sprintf(
        "`tables` must use values from: %s.",
        paste(valid_tables, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (
    !is.logical(include_fold_data) || length(include_fold_data) != 1L ||
      is.na(include_fold_data)
  ) {
    stop("`include_fold_data` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.character(na) || length(na) != 1L || is.na(na)) {
    stop(
      "`na` must be a single non-missing character value.",
      call. = FALSE
    )
  }

  tables <- unique(tables)
  directory <- path.expand(directory)

  if (!dir.exists(directory)) {
    created <- dir.create(directory, recursive = TRUE)

    if (!created && !dir.exists(directory)) {
      stop(
        sprintf("Could not create output directory: %s.", directory),
        call. = FALSE
      )
    }
  }

  output_data <- list(
    assignments = x$assignments,
    fold_summary = x$fold_summary,
    group_counts = x$group_counts,
    group_mapping = x$group_mapping,
    validation_checks = x$validation$checks,
    validation_issues = x$validation$issues,
    audit_summary = x$audit$summary,
    audit_checks = x$audit$checks,
    audit_issues = x$audit$issues
  )[tables]

  if (include_fold_data) {
    for (fold_object in x$folds) {
      for (partition_name in c("analysis", "assessment", "excluded")) {
        output_name <- paste(fold_object$fold_id, partition_name, sep = "_")
        output_data[[output_name]] <- fold_object[[partition_name]]
      }
    }
  }

  files <- file.path(
    directory,
    paste0(prefix, "_", names(output_data), ".csv")
  )
  names(files) <- names(output_data)
  existing <- files[file.exists(files)]

  if (length(existing) > 0L && !overwrite) {
    stop(
      sprintf(
        "Output files already exist: %s.",
        paste(existing, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (table_name in names(output_data)) {
    utils::write.csv(
      output_data[[table_name]],
      file = files[[table_name]],
      row.names = FALSE,
      na = na,
      fileEncoding = "UTF-8"
    )
  }

  normalized <- vapply(
    files,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )

  invisible(normalized)
}
