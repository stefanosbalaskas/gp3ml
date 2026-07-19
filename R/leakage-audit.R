.gp3ml_validate_column_name <- function(x, argument, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }

  if (
    !is.character(x) ||
    length(x) != 1L ||
    is.na(x) ||
    !nzchar(x)
  ) {
    stop(
      sprintf(
        "`%s` must be a single non-empty column name.",
        argument
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}


.gp3ml_validate_column_vector <- function(x, argument, allow_empty = TRUE) {
  if (!is.character(x)) {
    stop(
      sprintf("`%s` must be a character vector.", argument),
      call. = FALSE
    )
  }

  if (!allow_empty && length(x) == 0L) {
    stop(
      sprintf("`%s` must contain at least one column name.", argument),
      call. = FALSE
    )
  }

  if (
    anyNA(x) ||
    any(!nzchar(x)) ||
    anyDuplicated(x)
  ) {
    stop(
      sprintf(
        "`%s` must contain unique, non-missing, non-empty column names.",
        argument
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}


.gp3ml_missing_identifier <- function(x) {
  missing <- is.na(x)

  if (is.character(x) || is.factor(x)) {
    values <- trimws(as.character(x))
    missing <- missing | !nzchar(values)
  }

  missing
}


.gp3ml_identifier_values <- function(x) {
  missing <- .gp3ml_missing_identifier(x)
  unique(as.character(x[!missing]))
}


.gp3ml_trial_signatures <- function(
    data,
    trial_id,
    participant_id = NULL) {
  columns <- c(participant_id, trial_id)

  complete <- rep(TRUE, nrow(data))

  for (column in columns) {
    complete <- complete &
      !.gp3ml_missing_identifier(data[[column]])
  }

  if (!any(complete)) {
    return(character())
  }

  .gp3ml_row_signatures(
    data = data[complete, columns, drop = FALSE],
    columns = columns
  )
}


.gp3ml_canonical_data <- function(data, columns) {
  canonical <- data[columns]

  canonical[] <- lapply(
    canonical,
    function(x) {
      if (is.factor(x)) {
        return(as.character(x))
      }

      if (inherits(x, "POSIXt")) {
        return(
          format(
            x,
            format = "%Y-%m-%dT%H:%M:%OS6",
            tz = "UTC",
            usetz = FALSE
          )
        )
      }

      if (inherits(x, "Date")) {
        return(format(x, format = "%Y-%m-%d"))
      }

      if (inherits(x, "difftime")) {
        return(as.numeric(x, units = "secs"))
      }

      if (is.list(x) || is.matrix(x)) {
        stop(
          paste0(
            "Leakage signatures do not currently support list or ",
            "matrix columns."
          ),
          call. = FALSE
        )
      }

      x
    }
  )

  canonical
}


.gp3ml_row_signatures <- function(data, columns) {
  canonical <- .gp3ml_canonical_data(data, columns)

  if (nrow(canonical) == 0L) {
    return(character())
  }

  vapply(
    seq_len(nrow(canonical)),
    function(index) {
      row <- canonical[index, , drop = FALSE]
      row.names(row) <- NULL

      serialized <- serialize(
        row,
        connection = NULL,
        ascii = FALSE,
        version = 2
      )

      paste(as.character(serialized), collapse = "")
    },
    character(1)
  )
}


.gp3ml_partition_summary <- function(
    analysis,
    assessment,
    participant_id,
    trial_id,
    stimulus_id) {
  count_unique <- function(data, column) {
    if (is.null(column)) {
      return(NA_integer_)
    }

    as.integer(
      length(.gp3ml_identifier_values(data[[column]]))
    )
  }

  data.frame(
    partition = c("analysis", "assessment"),
    n_rows = c(nrow(analysis), nrow(assessment)),
    n_participants = c(
      count_unique(analysis, participant_id),
      count_unique(assessment, participant_id)
    ),
    n_trials = c(
      count_unique(analysis, trial_id),
      count_unique(assessment, trial_id)
    ),
    n_stimuli = c(
      count_unique(analysis, stimulus_id),
      count_unique(assessment, stimulus_id)
    ),
    stringsAsFactors = FALSE
  )
}


#' Audit leakage between predictive-analysis partitions
#'
#' Audits already-defined analysis and assessment partitions for common
#' forms of leakage and for incompatibility with a declared generalization
#' target. The function does not create data splits, preprocess variables,
#' select features, or fit predictive models.
#'
#' @param analysis A data frame containing the analysis or training
#'   partition.
#' @param assessment A data frame containing the assessment or test
#'   partition.
#' @param outcome A single column name identifying the outcome.
#' @param predictors A character vector identifying intended predictor
#'   columns.
#' @param participant_id An optional participant-identifier column.
#' @param trial_id An optional trial-identifier column.
#' @param stimulus_id An optional stimulus-identifier column.
#' @param generalization_target The predictive generalization target. One
#'   of `"new_trials_known_participants"`, `"new_participants"`,
#'   `"new_stimuli"`, or `"new_participants_and_new_stimuli"`.
#' @param target_derived Character vector of columns known to have been
#'   derived directly from the outcome.
#' @param post_outcome Character vector of columns measured or constructed
#'   after the outcome became available.
#'
#' @return An object of class `gazepoint_ml_leakage_audit`. The object
#'   contains an overall status, partition summary, complete check table,
#'   and machine-readable table of non-passing issues.
#'
#' @details
#' The overall status is `"fail"` when at least one failing check is
#' present, `"review"` when no failing checks are present but at least one
#' review item is present, and `"pass"` otherwise.
#'
#' When `participant_id` is supplied, trial overlap is evaluated using
#' composite participant-trial units. This permits trial labels such as
#' `"T01"` to be reused by different participants without being treated
#' as leakage. Without `participant_id`, `trial_id` is assumed to be
#' globally unique.
#'
#' The audit can identify structural leakage visible in the supplied
#' partitions and declared variable roles. It cannot prove that
#' preprocessing or feature selection was estimated inside resampling
#' folds. Those operations require separate provenance and resampling
#' safeguards.
#'
#' The function does not determine whether an outcome is scientifically
#' or ethically appropriate. All uses remain subject to the package
#' governance and prohibited-use statements.
#'
#' @examples
#' analysis <- data.frame(
#'   participant_id = c("P01", "P01", "P02", "P02"),
#'   trial_id = c("T01", "T02", "T03", "T04"),
#'   stimulus_id = c("S01", "S02", "S03", "S04"),
#'   outcome = c(0, 1, 0, 1),
#'   fixation_duration = c(210, 240, 225, 260),
#'   pupil_change = c(0.10, 0.16, 0.12, 0.18)
#' )
#'
#' assessment <- data.frame(
#'   participant_id = c("P03", "P03", "P04", "P04"),
#'   trial_id = c("T05", "T06", "T07", "T08"),
#'   stimulus_id = c("S05", "S06", "S07", "S08"),
#'   outcome = c(1, 0, 1, 0),
#'   fixation_duration = c(275, 230, 290, 245),
#'   pupil_change = c(0.21, 0.11, 0.24, 0.14)
#' )
#'
#' audit_gazepoint_ml_leakage(
#'   analysis = analysis,
#'   assessment = assessment,
#'   outcome = "outcome",
#'   predictors = c("fixation_duration", "pupil_change"),
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants"
#' )
#'
#' @export
audit_gazepoint_ml_leakage <- function(
    analysis,
    assessment,
    outcome,
    predictors,
    participant_id = NULL,
    trial_id = NULL,
    stimulus_id = NULL,
    generalization_target = c(
      "new_trials_known_participants",
      "new_participants",
      "new_stimuli",
      "new_participants_and_new_stimuli"
    ),
    target_derived = character(),
    post_outcome = character()) {
  generalization_target <- match.arg(generalization_target)

  if (!is.data.frame(analysis) || !is.data.frame(assessment)) {
    stop(
      "`analysis` and `assessment` must both be data frames.",
      call. = FALSE
    )
  }

  if (nrow(analysis) == 0L || nrow(assessment) == 0L) {
    stop(
      "`analysis` and `assessment` must each contain at least one row.",
      call. = FALSE
    )
  }

  if (
    anyDuplicated(names(analysis)) ||
    anyDuplicated(names(assessment))
  ) {
    stop(
      "Partition column names must be unique.",
      call. = FALSE
    )
  }

  if (!setequal(names(analysis), names(assessment))) {
    stop(
      paste0(
        "`analysis` and `assessment` must contain the same column ",
        "names."
      ),
      call. = FALSE
    )
  }

  assessment <- assessment[names(analysis)]

  .gp3ml_validate_column_name(outcome, "outcome")
  .gp3ml_validate_column_vector(
    predictors,
    "predictors",
    allow_empty = FALSE
  )
  .gp3ml_validate_column_name(
    participant_id,
    "participant_id",
    allow_null = TRUE
  )
  .gp3ml_validate_column_name(
    trial_id,
    "trial_id",
    allow_null = TRUE
  )
  .gp3ml_validate_column_name(
    stimulus_id,
    "stimulus_id",
    allow_null = TRUE
  )
  .gp3ml_validate_column_vector(target_derived, "target_derived")
  .gp3ml_validate_column_vector(post_outcome, "post_outcome")

  identifier_columns <- c(
    participant_id,
    trial_id,
    stimulus_id
  )

  if (anyDuplicated(identifier_columns)) {
    stop(
      "Participant, trial, and stimulus roles must use distinct columns.",
      call. = FALSE
    )
  }

  if (outcome %in% identifier_columns) {
    stop(
      "`outcome` must not also be declared as an identifier.",
      call. = FALSE
    )
  }

  declared_columns <- unique(
    c(
      outcome,
      predictors,
      identifier_columns,
      target_derived,
      post_outcome
    )
  )

  missing_columns <- setdiff(declared_columns, names(analysis))

  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "Declared columns not found in both partitions: %s.",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  checks <- list()

  add_check <- function(
    check_id,
    status,
    n_affected,
    columns,
    message,
    remediation) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check_id = check_id,
      status = status,
      n_affected = as.integer(n_affected),
      columns = paste(columns, collapse = ", "),
      message = message,
      remediation = remediation,
      stringsAsFactors = FALSE
    )
  }

  outcome_in_predictors <- intersect(outcome, predictors)

  add_check(
    check_id = "outcome_in_predictors",
    status = if (length(outcome_in_predictors)) "fail" else "pass",
    n_affected = length(outcome_in_predictors),
    columns = outcome_in_predictors,
    message = if (length(outcome_in_predictors)) {
      "The outcome is included in the intended predictor set."
    } else {
      "The outcome is not included in the intended predictor set."
    },
    remediation = if (length(outcome_in_predictors)) {
      "Remove the outcome from `predictors`."
    } else {
      "None."
    }
  )

  identifiers_in_predictors <- intersect(
    predictors,
    identifier_columns
  )

  add_check(
    check_id = "declared_identifier_in_predictors",
    status = if (length(identifiers_in_predictors)) "fail" else "pass",
    n_affected = length(identifiers_in_predictors),
    columns = identifiers_in_predictors,
    message = if (length(identifiers_in_predictors)) {
      "Declared identifiers are included in the predictor set."
    } else {
      "No declared identifiers are included in the predictor set."
    },
    remediation = if (length(identifiers_in_predictors)) {
      "Remove participant, trial, and stimulus identifiers from predictors."
    } else {
      "None."
    }
  )

  identifier_pattern <- paste0(
    "(^|_)",
    "(id|uuid|guid|identifier|record|row|index|",
    "filename|file_name|filepath|file_path|session_id)",
    "(_|$)"
  )

  identifier_like <- predictors[
    grepl(
      identifier_pattern,
      tolower(predictors),
      perl = TRUE
    )
  ]

  identifier_like <- setdiff(
    identifier_like,
    identifier_columns
  )

  add_check(
    check_id = "identifier_like_predictor_names",
    status = if (length(identifier_like)) "review" else "pass",
    n_affected = length(identifier_like),
    columns = identifier_like,
    message = if (length(identifier_like)) {
      paste0(
        "Some predictor names appear identifier-like and require ",
        "manual review."
      )
    } else {
      "No additional identifier-like predictor names were detected."
    },
    remediation = if (length(identifier_like)) {
      paste0(
        "Confirm that these variables contain scientific measurements ",
        "rather than identifiers or row-location information."
      )
    } else {
      "None."
    }
  )

  target_derived_predictors <- intersect(
    predictors,
    target_derived
  )

  add_check(
    check_id = "target_derived_predictors",
    status = if (length(target_derived_predictors)) "fail" else "pass",
    n_affected = length(target_derived_predictors),
    columns = target_derived_predictors,
    message = if (length(target_derived_predictors)) {
      "Declared target-derived variables are included as predictors."
    } else {
      "No declared target-derived variables are included as predictors."
    },
    remediation = if (length(target_derived_predictors)) {
      "Remove all outcome-derived variables from the predictor set."
    } else {
      "None."
    }
  )

  post_outcome_predictors <- intersect(
    predictors,
    post_outcome
  )

  add_check(
    check_id = "post_outcome_predictors",
    status = if (length(post_outcome_predictors)) "fail" else "pass",
    n_affected = length(post_outcome_predictors),
    columns = post_outcome_predictors,
    message = if (length(post_outcome_predictors)) {
      "Declared post-outcome variables are included as predictors."
    } else {
      "No declared post-outcome variables are included as predictors."
    },
    remediation = if (length(post_outcome_predictors)) {
      "Remove variables unavailable at the intended prediction time."
    } else {
      "None."
    }
  )

  analysis_rows <- .gp3ml_row_signatures(
    analysis,
    names(analysis)
  )
  assessment_rows <- .gp3ml_row_signatures(
    assessment,
    names(assessment)
  )

  overlapping_rows <- intersect(
    unique(analysis_rows),
    unique(assessment_rows)
  )

  add_check(
    check_id = "exact_row_overlap",
    status = if (length(overlapping_rows)) "fail" else "pass",
    n_affected = length(overlapping_rows),
    columns = names(analysis),
    message = if (length(overlapping_rows)) {
      "Exact row patterns occur in both partitions."
    } else {
      "No exact row patterns occur in both partitions."
    },
    remediation = if (length(overlapping_rows)) {
      "Reconstruct the partitions so that each sample occurs once."
    } else {
      "None."
    }
  )

  duplicate_analysis <- sum(duplicated(analysis_rows))
  duplicate_assessment <- sum(duplicated(assessment_rows))
  duplicate_rows <- duplicate_analysis + duplicate_assessment

  add_check(
    check_id = "duplicate_rows_within_partitions",
    status = if (duplicate_rows > 0L) "review" else "pass",
    n_affected = duplicate_rows,
    columns = names(analysis),
    message = if (duplicate_rows > 0L) {
      sprintf(
        paste0(
          "%d duplicate rows occur within the supplied partitions ",
          "(%d analysis; %d assessment)."
        ),
        duplicate_rows,
        duplicate_analysis,
        duplicate_assessment
      )
    } else {
      "No duplicate rows occur within either partition."
    },
    remediation = if (duplicate_rows > 0L) {
      "Confirm whether repeated rows are expected or accidental duplicates."
    } else {
      "None."
    }
  )

  analysis_predictors <- .gp3ml_row_signatures(
    analysis,
    predictors
  )
  assessment_predictors <- .gp3ml_row_signatures(
    assessment,
    predictors
  )

  overlapping_predictors <- intersect(
    unique(analysis_predictors),
    unique(assessment_predictors)
  )

  add_check(
    check_id = "predictor_profile_overlap",
    status = if (length(overlapping_predictors)) "review" else "pass",
    n_affected = length(overlapping_predictors),
    columns = predictors,
    message = if (length(overlapping_predictors)) {
      "Identical predictor profiles occur in both partitions."
    } else {
      "No identical predictor profiles occur in both partitions."
    },
    remediation = if (length(overlapping_predictors)) {
      paste0(
        "Inspect whether repeated profiles represent legitimate repeated ",
        "measurements, copied samples, or pre-split aggregation."
      )
    } else {
      "None."
    }
  )

  participant_required <- generalization_target %in% c(
    "new_trials_known_participants",
    "new_participants",
    "new_participants_and_new_stimuli"
  )

  add_check(
    check_id = "participant_id_available",
    status = if (!is.null(participant_id)) {
      "pass"
    } else if (participant_required) {
      "fail"
    } else {
      "review"
    },
    n_affected = as.integer(is.null(participant_id)),
    columns = participant_id,
    message = if (!is.null(participant_id)) {
      "A participant identifier was supplied."
    } else {
      "No participant identifier was supplied."
    },
    remediation = if (is.null(participant_id)) {
      "Supply `participant_id` to make participant overlap auditable."
    } else {
      "None."
    }
  )

  if (!is.null(participant_id)) {
    participant_missing <- sum(
      .gp3ml_missing_identifier(analysis[[participant_id]])
    ) + sum(
      .gp3ml_missing_identifier(assessment[[participant_id]])
    )

    add_check(
      check_id = "participant_id_missing",
      status = if (participant_missing == 0L) {
        "pass"
      } else if (participant_required) {
        "fail"
      } else {
        "review"
      },
      n_affected = participant_missing,
      columns = participant_id,
      message = if (participant_missing > 0L) {
        "Missing participant identifiers occur in the partitions."
      } else {
        "No participant identifiers are missing."
      },
      remediation = if (participant_missing > 0L) {
        "Resolve missing participant identifiers before evaluation."
      } else {
        "None."
      }
    )

    analysis_participants <- .gp3ml_identifier_values(
      analysis[[participant_id]]
    )
    assessment_participants <- .gp3ml_identifier_values(
      assessment[[participant_id]]
    )

    if (
      generalization_target ==
      "new_trials_known_participants"
    ) {
      incompatible_participants <- setdiff(
        assessment_participants,
        analysis_participants
      )

      participant_message <- if (length(incompatible_participants)) {
        paste0(
          "Assessment contains participants not represented in the ",
          "analysis partition."
        )
      } else {
        paste0(
          "All assessment participants are represented in the ",
          "analysis partition."
        )
      }
    } else if (
      generalization_target %in% c(
        "new_participants",
        "new_participants_and_new_stimuli"
      )
    ) {
      incompatible_participants <- intersect(
        analysis_participants,
        assessment_participants
      )

      participant_message <- if (length(incompatible_participants)) {
        "Participant identifiers overlap across partitions."
      } else {
        "Participant identifiers are disjoint across partitions."
      }
    } else {
      incompatible_participants <- character()
      participant_message <- paste0(
        "Participant overlap is not prohibited by the declared ",
        "new-stimulus target."
      )
    }

    add_check(
      check_id = "participant_partition_compatibility",
      status = if (length(incompatible_participants)) {
        "fail"
      } else {
        "pass"
      },
      n_affected = length(incompatible_participants),
      columns = participant_id,
      message = participant_message,
      remediation = if (length(incompatible_participants)) {
        paste0(
          "Reconstruct partitions to match the declared participant ",
          "generalization target."
        )
      } else {
        "None."
      }
    )
  }

  trial_required <- identical(
    generalization_target,
    "new_trials_known_participants"
  )

  add_check(
    check_id = "trial_id_available",
    status = if (!is.null(trial_id)) {
      "pass"
    } else if (trial_required) {
      "fail"
    } else {
      "review"
    },
    n_affected = as.integer(is.null(trial_id)),
    columns = trial_id,
    message = if (!is.null(trial_id)) {
      "A trial identifier was supplied."
    } else {
      "No trial identifier was supplied."
    },
    remediation = if (is.null(trial_id)) {
      "Supply `trial_id` to make trial overlap auditable."
    } else {
      "None."
    }
  )

  if (!is.null(trial_id)) {
    trial_missing <- sum(
      .gp3ml_missing_identifier(analysis[[trial_id]])
    ) + sum(
      .gp3ml_missing_identifier(assessment[[trial_id]])
    )

    add_check(
      check_id = "trial_id_missing",
      status = if (trial_missing == 0L) {
        "pass"
      } else if (trial_required) {
        "fail"
      } else {
        "review"
      },
      n_affected = trial_missing,
      columns = trial_id,
      message = if (trial_missing > 0L) {
        "Missing trial identifiers occur in the partitions."
      } else {
        "No trial identifiers are missing."
      },
      remediation = if (trial_missing > 0L) {
        "Resolve missing trial identifiers before evaluation."
      } else {
        "None."
      }
    )

    analysis_trials <- .gp3ml_trial_signatures(
      data = analysis,
      trial_id = trial_id,
      participant_id = participant_id
    )

    assessment_trials <- .gp3ml_trial_signatures(
      data = assessment,
      trial_id = trial_id,
      participant_id = participant_id
    )

    overlapping_trials <- intersect(
      unique(analysis_trials),
      unique(assessment_trials)
    )

    add_check(
      check_id = "trial_partition_overlap",
      status = if (length(overlapping_trials)) "fail" else "pass",
      n_affected = length(overlapping_trials),
      columns = trial_id,
      message = if (length(overlapping_trials)) {
        if (is.null(participant_id)) {
          "Trial identifiers overlap across partitions."
        } else {
          "Participant-trial units overlap across partitions."
        }
      } else {
        if (is.null(participant_id)) {
          "Trial identifiers are disjoint across partitions."
        } else {
          "Participant-trial units are disjoint across partitions."
        }
      },
      remediation = if (length(overlapping_trials)) {
        paste0(
          "Keep each participant-trial unit entirely within ",
          "one partition."
        )
      } else {
        "None."
      }
    )
  }

  stimulus_required <- generalization_target %in% c(
    "new_stimuli",
    "new_participants_and_new_stimuli"
  )

  add_check(
    check_id = "stimulus_id_available",
    status = if (!is.null(stimulus_id)) {
      "pass"
    } else if (stimulus_required) {
      "fail"
    } else {
      "review"
    },
    n_affected = as.integer(is.null(stimulus_id)),
    columns = stimulus_id,
    message = if (!is.null(stimulus_id)) {
      "A stimulus identifier was supplied."
    } else {
      "No stimulus identifier was supplied."
    },
    remediation = if (is.null(stimulus_id)) {
      "Supply `stimulus_id` to make stimulus overlap auditable."
    } else {
      "None."
    }
  )

  if (!is.null(stimulus_id)) {
    stimulus_missing <- sum(
      .gp3ml_missing_identifier(analysis[[stimulus_id]])
    ) + sum(
      .gp3ml_missing_identifier(assessment[[stimulus_id]])
    )

    add_check(
      check_id = "stimulus_id_missing",
      status = if (stimulus_missing == 0L) {
        "pass"
      } else if (stimulus_required) {
        "fail"
      } else {
        "review"
      },
      n_affected = stimulus_missing,
      columns = stimulus_id,
      message = if (stimulus_missing > 0L) {
        "Missing stimulus identifiers occur in the partitions."
      } else {
        "No stimulus identifiers are missing."
      },
      remediation = if (stimulus_missing > 0L) {
        "Resolve missing stimulus identifiers before evaluation."
      } else {
        "None."
      }
    )

    if (stimulus_required) {
      overlapping_stimuli <- intersect(
        .gp3ml_identifier_values(analysis[[stimulus_id]]),
        .gp3ml_identifier_values(assessment[[stimulus_id]])
      )

      stimulus_message <- if (length(overlapping_stimuli)) {
        "Stimulus identifiers overlap across partitions."
      } else {
        "Stimulus identifiers are disjoint across partitions."
      }
    } else {
      overlapping_stimuli <- character()
      stimulus_message <- paste0(
        "Stimulus overlap is not prohibited by the declared ",
        "generalization target."
      )
    }

    add_check(
      check_id = "stimulus_partition_compatibility",
      status = if (length(overlapping_stimuli)) {
        "fail"
      } else {
        "pass"
      },
      n_affected = length(overlapping_stimuli),
      columns = stimulus_id,
      message = stimulus_message,
      remediation = if (length(overlapping_stimuli)) {
        paste0(
          "Reconstruct partitions with disjoint stimuli for the ",
          "declared target."
        )
      } else {
        "None."
      }
    )
  }

  checks <- do.call(rbind, checks)
  row.names(checks) <- NULL

  issues <- checks[
    checks$status != "pass",
    ,
    drop = FALSE
  ]
  row.names(issues) <- NULL

  overall_status <- if (any(checks$status == "fail")) {
    "fail"
  } else if (any(checks$status == "review")) {
    "review"
  } else {
    "pass"
  }

  structure(
    list(
      status = overall_status,
      generalization_target = generalization_target,
      outcome = outcome,
      predictors = predictors,
      roles = list(
        participant_id = participant_id,
        trial_id = trial_id,
        stimulus_id = stimulus_id,
        target_derived = target_derived,
        post_outcome = post_outcome
      ),
      partition_summary = .gp3ml_partition_summary(
        analysis = analysis,
        assessment = assessment,
        participant_id = participant_id,
        trial_id = trial_id,
        stimulus_id = stimulus_id
      ),
      checks = checks,
      issues = issues,
      call = match.call()
    ),
    class = "gazepoint_ml_leakage_audit"
  )
}


#' Print a Gazepoint ML leakage audit
#'
#' @param x An object returned by
#'   [audit_gazepoint_ml_leakage()].
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_ml_leakage_audit <- function(x, ...) {
  cat("<gazepoint_ml_leakage_audit>\n")
  cat("Overall status: ", toupper(x$status), "\n", sep = "")
  cat(
    "Generalization target: ",
    x$generalization_target,
    "\n",
    sep = ""
  )

  analysis_rows <- x$partition_summary$n_rows[
    x$partition_summary$partition == "analysis"
  ]
  assessment_rows <- x$partition_summary$n_rows[
    x$partition_summary$partition == "assessment"
  ]

  cat(
    "Rows: ",
    analysis_rows,
    " analysis; ",
    assessment_rows,
    " assessment\n",
    sep = ""
  )

  cat("Non-passing checks: ", nrow(x$issues), "\n", sep = "")

  if (nrow(x$issues) == 0L) {
    cat("No leakage issues were detected by the implemented checks.\n")
  } else {
    display <- x$issues[
      ,
      c(
        "check_id",
        "status",
        "n_affected",
        "columns"
      ),
      drop = FALSE
    ]

    print(
      display,
      row.names = FALSE,
      right = FALSE
    )
  }

  invisible(x)
}

#' Write a Gazepoint ML leakage-audit table to CSV
#'
#' Writes one machine-readable table from a leakage-audit object to a
#' UTF-8 CSV file. Existing files are not replaced unless explicitly
#' permitted.
#'
#' @param x An object returned by
#'   [audit_gazepoint_ml_leakage()].
#' @param file A single output file path ending in `.csv`.
#' @param table The audit table to export. One of `"issues"`,
#'   `"checks"`, or `"partition_summary"`.
#' @param overwrite Logical. When `FALSE`, the default, an existing
#'   output file causes an error.
#' @param na Character value used for missing values in the CSV file.
#'
#' @return The normalized output path, invisibly.
#'
#' @examples
#' analysis <- data.frame(
#'   participant_id = c("P01", "P02"),
#'   trial_id = c("T01", "T02"),
#'   outcome = c(0, 1),
#'   feature = c(1.2, 1.8)
#' )
#'
#' assessment <- data.frame(
#'   participant_id = c("P03", "P04"),
#'   trial_id = c("T03", "T04"),
#'   outcome = c(1, 0),
#'   feature = c(2.1, 2.4)
#' )
#'
#' audit <- audit_gazepoint_ml_leakage(
#'   analysis = analysis,
#'   assessment = assessment,
#'   outcome = "outcome",
#'   predictors = "feature",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   generalization_target = "new_participants"
#' )
#'
#' output <- tempfile(fileext = ".csv")
#'
#' write_gazepoint_ml_leakage_audit_csv(
#'   audit,
#'   output,
#'   table = "checks"
#' )
#'
#' unlink(output)
#'
#' @export
write_gazepoint_ml_leakage_audit_csv <- function(
    x,
    file,
    table = c(
      "issues",
      "checks",
      "partition_summary"
    ),
    overwrite = FALSE,
    na = "") {
  if (!inherits(x, "gazepoint_ml_leakage_audit")) {
    stop(
      "`x` must inherit from `gazepoint_ml_leakage_audit`.",
      call. = FALSE
    )
  }

  if (
    !is.character(file) ||
    length(file) != 1L ||
    is.na(file) ||
    !nzchar(file)
  ) {
    stop(
      "`file` must be a single non-empty file path.",
      call. = FALSE
    )
  }

  if (!grepl("\\.csv$", file, ignore.case = TRUE)) {
    stop(
      "`file` must use a .csv extension.",
      call. = FALSE
    )
  }

  if (
    !is.logical(overwrite) ||
    length(overwrite) != 1L ||
    is.na(overwrite)
  ) {
    stop(
      "`overwrite` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.character(na) ||
    length(na) != 1L ||
    is.na(na)
  ) {
    stop(
      "`na` must be a single non-missing character value.",
      call. = FALSE
    )
  }

  table <- match.arg(table)
  file <- path.expand(file)

  output_directory <- dirname(file)

  if (!dir.exists(output_directory)) {
    stop(
      sprintf(
        "Output directory does not exist: %s.",
        output_directory
      ),
      call. = FALSE
    )
  }

  if (file.exists(file) && !overwrite) {
    stop(
      sprintf(
        "Output file already exists: %s.",
        file
      ),
      call. = FALSE
    )
  }

  output <- x[[table]]

  if (!is.data.frame(output)) {
    stop(
      sprintf(
        "Audit component `%s` is not a data frame.",
        table
      ),
      call. = FALSE
    )
  }

  utils::write.csv(
    output,
    file = file,
    row.names = FALSE,
    na = na,
    fileEncoding = "UTF-8"
  )

  invisible(
    normalizePath(
      file,
      winslash = "/",
      mustWork = TRUE
    )
  )
}
