.gp3ml_diagnostics_bind <- function(rows) {
  if (length(rows) == 0L) {
    return(data.frame())
  }

  result <- do.call(rbind, rows)
  row.names(result) <- NULL
  result
}


.gp3ml_diagnostics_overall_status <- function(status) {
  if (any(status == "fail")) {
    return("fail")
  }

  if (any(status == "review")) {
    return("review")
  }

  "pass"
}


.gp3ml_diagnostics_ratio <- function(numerator, denominator) {
  if (length(denominator) != 1L || is.na(denominator)) {
    return(NA_real_)
  }

  if (denominator == 0) {
    if (isTRUE(numerator == 0)) {
      return(NA_real_)
    }

    return(Inf)
  }

  as.numeric(numerator) / as.numeric(denominator)
}


.gp3ml_diagnostics_threshold <- function(x, argument) {
  if (
    length(x) != 1L ||
      !is.numeric(x) ||
      is.na(x) ||
      !is.finite(x) ||
      x < 1
  ) {
    stop(
      sprintf("`%s` must be one finite numeric value greater than or equal to 1.", argument),
      call. = FALSE
    )
  }

  as.numeric(x)
}


.gp3ml_diagnostics_numeric_summary <- function(values) {
  observed <- values[!is.na(values)]

  if (length(observed) == 0L) {
    return(c(
      n = 0,
      mean = NA_real_,
      sd = NA_real_,
      median = NA_real_,
      min = NA_real_,
      max = NA_real_
    ))
  }

  c(
    n = length(observed),
    mean = mean(observed),
    sd = if (length(observed) > 1L) stats::sd(observed) else NA_real_,
    median = stats::median(observed),
    min = min(observed),
    max = max(observed)
  )
}


#' Diagnose group-aware Gazepoint resampling folds
#'
#' Creates fold-size, repeat-level, grouping, assessment-coverage,
#' outcome-balance, and exclusion diagnostics for an existing
#' `gazepoint_group_folds` object.
#'
#' @param x A `gazepoint_group_folds` object.
#' @param imbalance_review Fold-size ratio above which diagnostics receive a
#'   `review` status.
#' @param imbalance_fail Fold-size ratio above which diagnostics receive a
#'   `fail` status.
#'
#' @return An object of class `gazepoint_fold_diagnostics`.
#'
#' @export
diagnose_gazepoint_group_folds <- function(
    x,
    imbalance_review = 1.5,
    imbalance_fail = 2) {
  if (!inherits(x, "gazepoint_group_folds")) {
    stop("`x` must be a `gazepoint_group_folds` object.", call. = FALSE)
  }

  imbalance_review <- .gp3ml_diagnostics_threshold(
    imbalance_review,
    "imbalance_review"
  )
  imbalance_fail <- .gp3ml_diagnostics_threshold(
    imbalance_fail,
    "imbalance_fail"
  )

  if (imbalance_fail < imbalance_review) {
    stop(
      "`imbalance_fail` must be greater than or equal to `imbalance_review`.",
      call. = FALSE
    )
  }

  required <- c(
    "folds",
    "assignments",
    "fold_summary",
    "group_counts",
    "metadata",
    "audit",
    "validation"
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

  required_summary <- c(
    "repeat",
    "fold",
    "fold_id",
    "n_total",
    "n_analysis",
    "n_assessment",
    "n_excluded",
    "assessment_prop_all",
    "assessment_prop_retained",
    "leakage_status"
  )
  missing_summary <- setdiff(required_summary, names(x$fold_summary))

  if (length(missing_summary) > 0L) {
    stop(
      sprintf(
        "Fold summary is missing columns: %s.",
        paste(missing_summary, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  outcome <- x$metadata$outcome

  if (
    length(outcome) != 1L ||
      !is.character(outcome) ||
      is.na(outcome) ||
      !nzchar(outcome)
  ) {
    stop("Fold metadata does not contain one valid outcome name.", call. = FALSE)
  }

  fold_metrics <- x$fold_summary
  fold_metrics$analysis_assessment_ratio <- mapply(
    .gp3ml_diagnostics_ratio,
    fold_metrics$n_analysis,
    fold_metrics$n_assessment
  )
  fold_metrics$excluded_prop <- ifelse(
    fold_metrics$n_total > 0,
    fold_metrics$n_excluded / fold_metrics$n_total,
    NA_real_
  )

  repeat_rows <- list()
  repeat_values <- sort(unique(fold_metrics[["repeat"]]))

  for (repeat_value in repeat_values) {
    current <- fold_metrics[
      fold_metrics[["repeat"]] == repeat_value,
      ,
      drop = FALSE
    ]

    assessment_min <- min(current$n_assessment)
    assessment_max <- max(current$n_assessment)
    analysis_min <- min(current$n_analysis)
    analysis_max <- max(current$n_analysis)

    repeat_rows[[length(repeat_rows) + 1L]] <- data.frame(
      check.names = FALSE,
      `repeat` = as.integer(repeat_value),
      n_folds = as.integer(nrow(current)),
      assessment_min = as.integer(assessment_min),
      assessment_max = as.integer(assessment_max),
      assessment_size_ratio = .gp3ml_diagnostics_ratio(
        assessment_max,
        assessment_min
      ),
      analysis_min = as.integer(analysis_min),
      analysis_max = as.integer(analysis_max),
      analysis_size_ratio = .gp3ml_diagnostics_ratio(
        analysis_max,
        analysis_min
      ),
      total_excluded = as.integer(sum(current$n_excluded)),
      mean_assessment_prop_all = mean(current$assessment_prop_all),
      mean_assessment_prop_retained = mean(
        current$assessment_prop_retained
      ),
      stringsAsFactors = FALSE
    )
  }

  repeat_metrics <- .gp3ml_diagnostics_bind(repeat_rows)

  required_group_columns <- c(
    "repeat",
    "fold",
    "fold_id",
    "partition",
    "unit",
    "n_groups"
  )
  missing_group_columns <- setdiff(
    required_group_columns,
    names(x$group_counts)
  )

  if (length(missing_group_columns) > 0L) {
    stop(
      sprintf(
        "Group counts are missing columns: %s.",
        paste(missing_group_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  group_keys <- unique(
    x$group_counts[
      ,
      c("repeat", "fold", "fold_id", "unit"),
      drop = FALSE
    ]
  )
  group_rows <- list()

  for (index in seq_len(nrow(group_keys))) {
    key <- group_keys[index, , drop = FALSE]
    current <- x$group_counts[
      x$group_counts[["repeat"]] == key[["repeat"]] &
        x$group_counts$fold == key$fold &
        x$group_counts$fold_id == key$fold_id &
        x$group_counts$unit == key$unit,
      ,
      drop = FALSE
    ]

    count_partition <- function(partition) {
      values <- current$n_groups[current$partition == partition]

      if (length(values) == 0L) {
        return(0L)
      }

      as.integer(sum(values))
    }

    n_analysis_groups <- count_partition("analysis")
    n_assessment_groups <- count_partition("assessment")
    n_excluded_groups <- count_partition("excluded")

    group_rows[[length(group_rows) + 1L]] <- data.frame(
      check.names = FALSE,
      `repeat` = as.integer(key[["repeat"]]),
      fold = as.integer(key$fold),
      fold_id = as.character(key$fold_id),
      unit = as.character(key$unit),
      n_analysis_groups = n_analysis_groups,
      n_assessment_groups = n_assessment_groups,
      n_excluded_groups = n_excluded_groups,
      analysis_assessment_group_ratio = .gp3ml_diagnostics_ratio(
        n_analysis_groups,
        n_assessment_groups
      ),
      stringsAsFactors = FALSE
    )
  }

  group_balance <- .gp3ml_diagnostics_bind(group_rows)

  required_assignment_columns <- c(
    "repeat",
    "source_row",
    "partition"
  )
  missing_assignment_columns <- setdiff(
    required_assignment_columns,
    names(x$assignments)
  )

  if (length(missing_assignment_columns) > 0L) {
    stop(
      sprintf(
        "Assignments are missing columns: %s.",
        paste(missing_assignment_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  coverage_values <- data.frame(
    n_analysis = as.integer(x$assignments$partition == "analysis"),
    n_assessment = as.integer(x$assignments$partition == "assessment"),
    n_excluded = as.integer(x$assignments$partition == "excluded"),
    stringsAsFactors = FALSE
  )

  assessment_coverage <- stats::aggregate(
    coverage_values,
    by = list(
      `repeat` = x$assignments[["repeat"]],
      source_row = x$assignments$source_row
    ),
    FUN = sum
  )
  assessment_coverage[["repeat"]] <- as.integer(
    assessment_coverage[["repeat"]]
  )
  assessment_coverage$source_row <- as.integer(
    assessment_coverage$source_row
  )
  assessment_coverage <- assessment_coverage[
    order(
      assessment_coverage[["repeat"]],
      assessment_coverage$source_row
    ),
    ,
    drop = FALSE
  ]
  row.names(assessment_coverage) <- NULL

  first_fold <- x$folds[[1L]]
  partition_names <- c("analysis", "assessment", "excluded")
  prototype <- NULL
  source_character <- character()
  source_numeric <- numeric()

  for (partition_name in partition_names) {
    partition_data <- first_fold[[partition_name]]

    if (
      !is.data.frame(partition_data) ||
        !outcome %in% names(partition_data)
    ) {
      stop(
        sprintf(
          "Fold partitions must contain outcome column `%s`.",
          outcome
        ),
        call. = FALSE
      )
    }

    values <- partition_data[[outcome]]

    if (is.null(prototype) && length(values) > 0L) {
      prototype <- values
    }

    source_character <- c(
      source_character,
      as.character(values[!is.na(values)])
    )

    if (is.numeric(values)) {
      source_numeric <- c(
        source_numeric,
        as.numeric(values[!is.na(values)])
      )
    }
  }

  if (is.null(prototype)) {
    prototype <- first_fold$analysis[[outcome]]
  }

  outcome_is_continuous <- is.numeric(prototype) &&
    length(unique(source_numeric)) > 10L

  categorical_levels <- if (outcome_is_continuous) {
    character()
  } else if (is.factor(prototype)) {
    unique(c(levels(prototype), sort(unique(source_character))))
  } else {
    sort(unique(source_character))
  }

  outcome_rows <- list()

  for (fold_object in x$folds) {
    for (partition_name in partition_names) {
      values <- fold_object[[partition_name]][[outcome]]
      n_missing <- as.integer(sum(is.na(values)))

      if (outcome_is_continuous) {
        numeric_summary <- .gp3ml_diagnostics_numeric_summary(
          as.numeric(values)
        )

        outcome_rows[[length(outcome_rows) + 1L]] <- data.frame(
          check.names = FALSE,
          `repeat` = as.integer(fold_object[["repeat"]]),
          fold = as.integer(fold_object$fold),
          fold_id = as.character(fold_object$fold_id),
          partition = partition_name,
          metric_type = "numeric",
          outcome_level = NA_character_,
          n = as.integer(numeric_summary[["n"]]),
          proportion = NA_real_,
          n_missing = n_missing,
          mean = as.numeric(numeric_summary[["mean"]]),
          sd = as.numeric(numeric_summary[["sd"]]),
          median = as.numeric(numeric_summary[["median"]]),
          min = as.numeric(numeric_summary[["min"]]),
          max = as.numeric(numeric_summary[["max"]]),
          stringsAsFactors = FALSE
        )
      } else {
        observed <- as.character(values[!is.na(values)])
        denominator <- length(observed)
        levels_to_use <- categorical_levels

        if (length(levels_to_use) == 0L) {
          levels_to_use <- NA_character_
        }

        for (outcome_level in levels_to_use) {
          level_count <- if (is.na(outcome_level)) {
            0L
          } else {
            as.integer(sum(observed == outcome_level))
          }

          outcome_rows[[length(outcome_rows) + 1L]] <- data.frame(
            check.names = FALSE,
            `repeat` = as.integer(fold_object[["repeat"]]),
            fold = as.integer(fold_object$fold),
            fold_id = as.character(fold_object$fold_id),
            partition = partition_name,
            metric_type = "categorical",
            outcome_level = outcome_level,
            n = level_count,
            proportion = if (denominator > 0L) {
              level_count / denominator
            } else {
              NA_real_
            },
            n_missing = n_missing,
            mean = NA_real_,
            sd = NA_real_,
            median = NA_real_,
            min = NA_real_,
            max = NA_real_,
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  outcome_balance <- .gp3ml_diagnostics_bind(outcome_rows)

  exclusion_summary <- fold_metrics[
    ,
    c(
      "repeat",
      "fold",
      "fold_id",
      "n_total",
      "n_excluded",
      "excluded_prop"
    ),
    drop = FALSE
  ]

  metadata <- list(
    outcome = outcome,
    generalization_target = x$metadata$generalization_target,
    repeats = as.integer(x$metadata$repeats),
    n_source_rows = as.integer(x$metadata$n_source_rows),
    n_folds_total = as.integer(x$metadata$n_folds_total),
    imbalance_review = imbalance_review,
    imbalance_fail = imbalance_fail,
    outcome_type = if (outcome_is_continuous) {
      "numeric"
    } else {
      "categorical"
    },
    source_validation_status = x$validation$status,
    source_audit_status = x$audit$status
  )

  result <- structure(
    list(
      fold_metrics = fold_metrics,
      repeat_metrics = repeat_metrics,
      outcome_balance = outcome_balance,
      group_balance = group_balance,
      assessment_coverage = assessment_coverage,
      exclusion_summary = exclusion_summary,
      metadata = metadata,
      call = match.call()
    ),
    class = "gazepoint_fold_diagnostics"
  )

  result$validation <- validate_gazepoint_fold_diagnostics(result)
  result
}


#' Validate Gazepoint fold diagnostics
#'
#' @param x A `gazepoint_fold_diagnostics` object.
#'
#' @return An object of class `gazepoint_fold_diagnostics_validation`.
#'
#' @export
validate_gazepoint_fold_diagnostics <- function(x) {
  if (!inherits(x, "gazepoint_fold_diagnostics")) {
    stop(
      "`x` must be a `gazepoint_fold_diagnostics` object.",
      call. = FALSE
    )
  }

  required <- c(
    "fold_metrics",
    "repeat_metrics",
    "outcome_balance",
    "group_balance",
    "assessment_coverage",
    "exclusion_summary",
    "metadata"
  )
  missing_components <- setdiff(required, names(x))

  if (length(missing_components) > 0L) {
    stop(
      sprintf(
        "Diagnostics object is missing components: %s.",
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

  fold_metrics <- x$fold_metrics

  fold_count_ok <- identical(
    as.integer(nrow(fold_metrics)),
    as.integer(x$metadata$n_folds_total)
  )
  add_check(
    "fold_count",
    if (fold_count_ok) "pass" else "fail",
    sprintf(
      "Observed %d diagnostic fold rows; expected %d.",
      nrow(fold_metrics),
      x$metadata$n_folds_total
    ),
    "Recreate diagnostics from the complete fold-plan object."
  )

  fold_id_ok <- nrow(fold_metrics) > 0L &&
    !anyNA(fold_metrics$fold_id) &&
    all(nzchar(fold_metrics$fold_id)) &&
    !anyDuplicated(fold_metrics$fold_id)
  add_check(
    "fold_identifiers",
    if (fold_id_ok) "pass" else "fail",
    if (fold_id_ok) {
      "Fold identifiers are complete and unique."
    } else {
      "Fold identifiers are missing, empty, or duplicated."
    },
    "Recreate the underlying resampling plan before diagnostics."
  )

  observed_repeats <- sort(unique(fold_metrics[["repeat"]]))
  expected_repeats <- seq_len(as.integer(x$metadata$repeats))
  repeat_ok <- identical(
    as.integer(observed_repeats),
    as.integer(expected_repeats)
  )
  add_check(
    "repeat_structure",
    if (repeat_ok) "pass" else "fail",
    if (repeat_ok) {
      "Repeat identifiers match the declared repeat count."
    } else {
      "Repeat identifiers do not match the declared repeat count."
    },
    "Recreate diagnostics from an unmodified fold-plan object."
  )

  accounting_ok <- all(
    fold_metrics$n_total ==
      fold_metrics$n_analysis +
      fold_metrics$n_assessment +
      fold_metrics$n_excluded
  )
  add_check(
    "partition_row_accounting",
    if (accounting_ok) "pass" else "fail",
    if (accounting_ok) {
      "Analysis, assessment, and excluded rows reconcile to fold totals."
    } else {
      "At least one fold has inconsistent partition row accounting."
    },
    "Inspect and recreate the affected fold assignments."
  )

  nonempty_ok <- all(
    fold_metrics$n_analysis > 0L &
      fold_metrics$n_assessment > 0L
  )
  add_check(
    "nonempty_analysis_and_assessment",
    if (nonempty_ok) "pass" else "fail",
    if (nonempty_ok) {
      "All folds contain non-empty analysis and assessment partitions."
    } else {
      "At least one fold has an empty analysis or assessment partition."
    },
    "Reduce the fold count or increase the number of grouping units."
  )

  coverage <- x$assessment_coverage
  coverage_ok <- nrow(coverage) > 0L &&
    all(coverage$n_assessment == 1L)
  add_check(
    "assessment_coverage_once_per_repeat",
    if (coverage_ok) "pass" else "fail",
    if (coverage_ok) {
      "Every source row is assessed exactly once per repeat."
    } else {
      "At least one source row is assessed zero or multiple times in a repeat."
    },
    "Recreate diagnostics from the original, undamaged fold assignments."
  )

  ratios <- x$repeat_metrics$assessment_size_ratio
  finite_ratios <- ratios[!is.na(ratios)]
  maximum_ratio <- if (length(finite_ratios) == 0L) {
    NA_real_
  } else {
    max(finite_ratios)
  }

  imbalance_status <- if (
    any(is.infinite(finite_ratios)) ||
      (!is.na(maximum_ratio) &&
        maximum_ratio > x$metadata$imbalance_fail)
  ) {
    "fail"
  } else if (
    !is.na(maximum_ratio) &&
      maximum_ratio > x$metadata$imbalance_review
  ) {
    "review"
  } else {
    "pass"
  }
  add_check(
    "assessment_fold_size_balance",
    imbalance_status,
    if (is.na(maximum_ratio)) {
      "Assessment fold-size balance could not be calculated."
    } else {
      sprintf(
        "Maximum within-repeat assessment fold-size ratio is %.3f.",
        maximum_ratio
      )
    },
    "Inspect grouping-unit sizes or use a smaller fold count."
  )

  group_ok <- nrow(x$group_balance) > 0L &&
    all(x$group_balance$n_assessment_groups > 0L)
  add_check(
    "assessment_group_presence",
    if (group_ok) "pass" else "fail",
    if (group_ok) {
      "Every fold contains assessment groups for each recorded unit type."
    } else {
      "At least one fold lacks assessment groups for a recorded unit type."
    },
    "Inspect the requested generalization target and grouping identifiers."
  )

  categorical_assessment <- x$outcome_balance[
    x$outcome_balance$metric_type == "categorical" &
      x$outcome_balance$partition == "assessment",
    ,
    drop = FALSE
  ]
  missing_levels <- nrow(categorical_assessment) > 0L &&
    any(categorical_assessment$n == 0L)

  add_check(
    "assessment_outcome_level_presence",
    if (missing_levels) "review" else "pass",
    if (nrow(categorical_assessment) == 0L) {
      "Outcome-level presence is not applicable to a continuous numeric outcome."
    } else if (missing_levels) {
      "At least one categorical outcome level is absent from an assessment fold."
    } else {
      "Every categorical outcome level is represented in every assessment fold."
    },
    "Inspect stratification feasibility and report sparse assessment folds."
  )

  leakage_status <- if (any(fold_metrics$leakage_status == "fail")) {
    "fail"
  } else if (any(fold_metrics$leakage_status == "review")) {
    "review"
  } else {
    "pass"
  }
  add_check(
    "embedded_leakage_audits",
    leakage_status,
    sprintf(
      "Embedded fold leakage statuses: %s.",
      paste(
        sort(unique(fold_metrics$leakage_status)),
        collapse = ", "
      )
    ),
    "Resolve all non-passing embedded leakage-audit findings."
  )

  source_status <- c(
    x$metadata$source_validation_status,
    x$metadata$source_audit_status
  )
  source_check_status <- if (any(source_status == "fail")) {
    "fail"
  } else if (any(source_status == "review")) {
    "review"
  } else {
    "pass"
  }
  add_check(
    "source_plan_status",
    source_check_status,
    sprintf(
      "Source fold validation is `%s`; source audit is `%s`.",
      x$metadata$source_validation_status,
      x$metadata$source_audit_status
    ),
    "Resolve non-passing source fold validation or audit results."
  )

  checks <- .gp3ml_diagnostics_bind(checks)
  issues <- checks[checks$status != "pass", , drop = FALSE]
  row.names(issues) <- NULL

  status_levels <- c("pass", "review", "fail")
  summary <- data.frame(
    status = status_levels,
    n_checks = vapply(
      status_levels,
      function(status) {
        sum(checks$status == status)
      },
      integer(1)
    ),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      status = .gp3ml_diagnostics_overall_status(checks$status),
      summary = summary,
      checks = checks,
      issues = issues,
      call = match.call()
    ),
    class = "gazepoint_fold_diagnostics_validation"
  )
}


#' Print Gazepoint fold diagnostics
#'
#' @param x A `gazepoint_fold_diagnostics` object.
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_fold_diagnostics <- function(x, ...) {
  cat("<gazepoint_fold_diagnostics>\n")
  cat(
    "Target: ",
    x$metadata$generalization_target,
    "\n",
    sep = ""
  )
  cat("Repeats: ", x$metadata$repeats, "\n", sep = "")
  cat("Folds: ", nrow(x$fold_metrics), "\n", sep = "")
  cat("Outcome type: ", x$metadata$outcome_type, "\n", sep = "")
  cat(
    "Diagnostic status: ",
    toupper(x$validation$status),
    "\n",
    sep = ""
  )

  maximum_ratio <- suppressWarnings(
    max(
      x$repeat_metrics$assessment_size_ratio,
      na.rm = TRUE
    )
  )

  if (is.finite(maximum_ratio)) {
    cat(
      "Maximum assessment-size ratio: ",
      format(round(maximum_ratio, 3), nsmall = 3),
      "\n",
      sep = ""
    )
  }

  invisible(x)
}


#' Print Gazepoint fold-diagnostics validation
#'
#' @param x A `gazepoint_fold_diagnostics_validation` object.
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_fold_diagnostics_validation <- function(x, ...) {
  cat("<gazepoint_fold_diagnostics_validation>\n")
  cat("Overall status: ", toupper(x$status), "\n", sep = "")

  for (status in c("pass", "review", "fail")) {
    n_checks <- x$summary$n_checks[x$summary$status == status]
    cat(
      paste0(tools::toTitleCase(status), ": "),
      n_checks,
      "\n",
      sep = ""
    )
  }

  invisible(x)
}


#' Write Gazepoint fold diagnostics to CSV files
#'
#' @param x A `gazepoint_fold_diagnostics` object.
#' @param directory Output directory.
#' @param prefix File-name prefix.
#' @param tables Diagnostic tables to export.
#' @param overwrite Whether existing files may be overwritten.
#' @param na String used for missing values.
#'
#' @return A named character vector of written file paths, invisibly.
#'
#' @export
write_gazepoint_fold_diagnostics_csv <- function(
    x,
    directory,
    prefix = "gazepoint_fold_diagnostics",
    tables = c(
      "fold_metrics",
      "repeat_metrics",
      "outcome_balance",
      "group_balance",
      "assessment_coverage",
      "exclusion_summary",
      "validation_checks",
      "validation_issues"
    ),
    overwrite = FALSE,
    na = "") {
  if (!inherits(x, "gazepoint_fold_diagnostics")) {
    stop(
      "`x` must be a `gazepoint_fold_diagnostics` object.",
      call. = FALSE
    )
  }

  if (
    length(directory) != 1L ||
      !is.character(directory) ||
      is.na(directory) ||
      !nzchar(directory)
  ) {
    stop("`directory` must be one non-empty path.", call. = FALSE)
  }

  if (
    length(prefix) != 1L ||
      !is.character(prefix) ||
      is.na(prefix) ||
      !nzchar(prefix)
  ) {
    stop("`prefix` must be one non-empty string.", call. = FALSE)
  }

  if (
    length(overwrite) != 1L ||
      !is.logical(overwrite) ||
      is.na(overwrite)
  ) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  available <- c(
    "fold_metrics",
    "repeat_metrics",
    "outcome_balance",
    "group_balance",
    "assessment_coverage",
    "exclusion_summary",
    "validation_checks",
    "validation_issues"
  )

  if (
    !is.character(tables) ||
      length(tables) == 0L ||
      anyNA(tables) ||
      any(!nzchar(tables))
  ) {
    stop("`tables` must contain one or more table names.", call. = FALSE)
  }

  unknown <- setdiff(tables, available)

  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "Unknown diagnostic tables: %s.",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  tables <- unique(tables)

  if (!dir.exists(directory)) {
    created <- dir.create(
      directory,
      recursive = TRUE,
      showWarnings = FALSE
    )

    if (!created && !dir.exists(directory)) {
      stop("Could not create `directory`.", call. = FALSE)
    }
  }

  table_values <- list(
    fold_metrics = x$fold_metrics,
    repeat_metrics = x$repeat_metrics,
    outcome_balance = x$outcome_balance,
    group_balance = x$group_balance,
    assessment_coverage = x$assessment_coverage,
    exclusion_summary = x$exclusion_summary,
    validation_checks = x$validation$checks,
    validation_issues = x$validation$issues
  )

  paths <- file.path(
    directory,
    paste0(prefix, "_", tables, ".csv")
  )
  names(paths) <- tables

  existing <- paths[file.exists(paths)]

  if (length(existing) > 0L && !overwrite) {
    stop(
      sprintf(
        "Refusing to overwrite existing files: %s.",
        paste(basename(existing), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (table_name in tables) {
    utils::write.csv(
      table_values[[table_name]],
      paths[[table_name]],
      row.names = FALSE,
      na = na
    )
  }

  invisible(paths)
}
