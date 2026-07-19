.gp3ml_manifest_required_columns <- function() {
  c(
    "feature",
    "scientific_source",
    "source_table",
    "transformation",
    "availability_stage",
    "prediction_time_available",
    "outcome_derived",
    "post_outcome",
    "identifier",
    "preprocessing_scope",
    "fold_local_required",
    "reviewer_notes"
  )
}


.gp3ml_manifest_availability_stages <- function() {
  c(
    "pre_exposure",
    "during_exposure",
    "post_exposure_pre_outcome",
    "at_prediction",
    "post_outcome",
    "unknown"
  )
}


.gp3ml_manifest_preprocessing_scopes <- function() {
  c(
    "none",
    "global",
    "analysis_partition",
    "resampling_fold",
    "unknown"
  )
}


.gp3ml_manifest_missing_text <- function(x) {
  is.na(x) | !nzchar(trimws(x))
}


.gp3ml_manifest_recycle <- function(
    x,
    n,
    argument,
    type = c("character", "logical"),
    allow_na = TRUE) {
  type <- match.arg(type)

  if (!(length(x) %in% c(1L, n))) {
    stop(
      sprintf(
        "`%s` must have length 1 or length %d.",
        argument,
        n
      ),
      call. = FALSE
    )
  }

  if (type == "character" && !is.character(x)) {
    stop(
      sprintf("`%s` must be a character vector.", argument),
      call. = FALSE
    )
  }

  if (type == "logical" && !is.logical(x)) {
    stop(
      sprintf("`%s` must be a logical vector.", argument),
      call. = FALSE
    )
  }

  if (!allow_na && anyNA(x)) {
    stop(
      sprintf("`%s` must not contain missing values.", argument),
      call. = FALSE
    )
  }

  if (length(x) == 1L) {
    x <- rep(x, n)
  }

  x
}


.gp3ml_as_feature_manifest <- function(x) {
  if (!is.data.frame(x)) {
    stop(
      "`x` must be a feature-manifest data frame.",
      call. = FALSE
    )
  }

  required <- .gp3ml_manifest_required_columns()
  missing_columns <- setdiff(required, names(x))

  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "Feature manifest is missing required columns: %s.",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (anyDuplicated(names(x))) {
    stop(
      "Feature-manifest column names must be unique.",
      call. = FALSE
    )
  }

  character_columns <- c(
    "feature",
    "scientific_source",
    "source_table",
    "transformation",
    "availability_stage",
    "preprocessing_scope",
    "reviewer_notes"
  )

  logical_columns <- c(
    "prediction_time_available",
    "outcome_derived",
    "post_outcome",
    "identifier",
    "fold_local_required"
  )

  invalid_character <- character_columns[
    !vapply(
      x[character_columns],
      is.character,
      logical(1)
    )
  ]

  if (length(invalid_character) > 0L) {
    stop(
      sprintf(
        "Manifest columns must be character: %s.",
        paste(invalid_character, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invalid_logical <- logical_columns[
    !vapply(
      x[logical_columns],
      is.logical,
      logical(1)
    )
  ]

  if (length(invalid_logical) > 0L) {
    stop(
      sprintf(
        "Manifest columns must be logical: %s.",
        paste(invalid_logical, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  feature <- trimws(x$feature)

  if (
    nrow(x) == 0L ||
    anyNA(feature) ||
    any(!nzchar(feature)) ||
    anyDuplicated(feature)
  ) {
    stop(
      paste0(
        "`feature` must contain unique, non-missing, ",
        "non-empty names."
      ),
      call. = FALSE
    )
  }

  x$feature <- feature

  valid_stages <- .gp3ml_manifest_availability_stages()

  invalid_stages <- unique(
    x$availability_stage[
      is.na(x$availability_stage) |
        !(x$availability_stage %in% valid_stages)
    ]
  )

  if (length(invalid_stages) > 0L) {
    stop(
      sprintf(
        paste0(
          "`availability_stage` must use one of: %s."
        ),
        paste(valid_stages, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  valid_scopes <- .gp3ml_manifest_preprocessing_scopes()

  invalid_scopes <- unique(
    x$preprocessing_scope[
      is.na(x$preprocessing_scope) |
        !(x$preprocessing_scope %in% valid_scopes)
    ]
  )

  if (length(invalid_scopes) > 0L) {
    stop(
      sprintf(
        "`preprocessing_scope` must use one of: %s.",
        paste(valid_scopes, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  ordered_columns <- c(
    required,
    setdiff(names(x), required)
  )

  x <- x[ordered_columns]

  class(x) <- unique(
    c(
      "gazepoint_feature_manifest",
      class(x)
    )
  )

  x
}


#' Create a Gazepoint feature-provenance manifest
#'
#' Creates a structured provenance manifest for intended predictive
#' features. Each row records where a feature originated, when it became
#' available, whether it is outcome-derived or post-outcome, and where
#' any data-dependent preprocessing was estimated.
#'
#' @param features Character vector of unique feature names.
#' @param scientific_source Scientific or measurement source for each
#'   feature.
#' @param source_table Source export, table, or object for each feature.
#' @param transformation Description of the transformation used to
#'   construct each feature.
#' @param availability_stage Availability stage for each feature. One of
#'   `"pre_exposure"`, `"during_exposure"`,
#'   `"post_exposure_pre_outcome"`, `"at_prediction"`,
#'   `"post_outcome"`, or `"unknown"`.
#' @param prediction_time_available Logical vector indicating whether
#'   each feature is available at the intended prediction time.
#' @param outcome_derived Logical vector indicating whether each feature
#'   was derived directly or indirectly from the outcome.
#' @param post_outcome Logical vector indicating whether each feature was
#'   measured or constructed after the outcome became available.
#' @param identifier Logical vector indicating whether each feature is an
#'   identifier or row-location variable.
#' @param preprocessing_scope Scope in which any data-dependent
#'   preprocessing was estimated. One of `"none"`, `"global"`,
#'   `"analysis_partition"`, `"resampling_fold"`, or `"unknown"`.
#' @param fold_local_required Logical vector indicating whether
#'   preprocessing for each feature must be estimated separately inside
#'   each resampling fold.
#' @param reviewer_notes Optional reviewer-facing notes.
#'
#' @return A data frame of class `gazepoint_feature_manifest`.
#'
#' @details
#' Each row is treated as an intended predictor. Consequently,
#' outcome-derived, post-outcome, unavailable, and identifier features
#' are treated as failing conditions by
#' [validate_gazepoint_feature_manifest()].
#'
#' The manifest records declared provenance. It does not independently
#' prove that preprocessing was estimated within the stated scope.
#'
#' @examples
#' manifest <- create_gazepoint_feature_manifest(
#'   features = c("fixation_duration", "pupil_change"),
#'   scientific_source = c(
#'     "Gazepoint fixation export",
#'     "Gazepoint all-gaze export"
#'   ),
#'   source_table = c("fixations", "all_gaze"),
#'   transformation = c(
#'     "Trial-level mean",
#'     "Baseline-adjusted change"
#'   ),
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = c("none", "resampling_fold"),
#'   fold_local_required = c(FALSE, TRUE)
#' )
#'
#' manifest
#'
#' @export
create_gazepoint_feature_manifest <- function(
    features,
    scientific_source = NA_character_,
    source_table = NA_character_,
    transformation = "none",
    availability_stage = "unknown",
    prediction_time_available = NA,
    outcome_derived = FALSE,
    post_outcome = FALSE,
    identifier = FALSE,
    preprocessing_scope = "unknown",
    fold_local_required = NA,
    reviewer_notes = "") {
  if (!is.character(features) || length(features) == 0L) {
    stop(
      "`features` must be a non-empty character vector.",
      call. = FALSE
    )
  }

  features <- trimws(features)

  if (
    anyNA(features) ||
    any(!nzchar(features)) ||
    anyDuplicated(features)
  ) {
    stop(
      paste0(
        "`features` must contain unique, non-missing, ",
        "non-empty names."
      ),
      call. = FALSE
    )
  }

  n <- length(features)

  scientific_source <- .gp3ml_manifest_recycle(
    scientific_source,
    n,
    "scientific_source",
    type = "character"
  )

  source_table <- .gp3ml_manifest_recycle(
    source_table,
    n,
    "source_table",
    type = "character"
  )

  transformation <- .gp3ml_manifest_recycle(
    transformation,
    n,
    "transformation",
    type = "character"
  )

  availability_stage <- .gp3ml_manifest_recycle(
    availability_stage,
    n,
    "availability_stage",
    type = "character",
    allow_na = FALSE
  )

  prediction_time_available <- .gp3ml_manifest_recycle(
    prediction_time_available,
    n,
    "prediction_time_available",
    type = "logical"
  )

  outcome_derived <- .gp3ml_manifest_recycle(
    outcome_derived,
    n,
    "outcome_derived",
    type = "logical",
    allow_na = FALSE
  )

  post_outcome <- .gp3ml_manifest_recycle(
    post_outcome,
    n,
    "post_outcome",
    type = "logical",
    allow_na = FALSE
  )

  identifier <- .gp3ml_manifest_recycle(
    identifier,
    n,
    "identifier",
    type = "logical",
    allow_na = FALSE
  )

  preprocessing_scope <- .gp3ml_manifest_recycle(
    preprocessing_scope,
    n,
    "preprocessing_scope",
    type = "character",
    allow_na = FALSE
  )

  fold_local_required <- .gp3ml_manifest_recycle(
    fold_local_required,
    n,
    "fold_local_required",
    type = "logical"
  )

  reviewer_notes <- .gp3ml_manifest_recycle(
    reviewer_notes,
    n,
    "reviewer_notes",
    type = "character"
  )

  manifest <- data.frame(
    feature = features,
    scientific_source = scientific_source,
    source_table = source_table,
    transformation = transformation,
    availability_stage = availability_stage,
    prediction_time_available = prediction_time_available,
    outcome_derived = outcome_derived,
    post_outcome = post_outcome,
    identifier = identifier,
    preprocessing_scope = preprocessing_scope,
    fold_local_required = fold_local_required,
    reviewer_notes = reviewer_notes,
    stringsAsFactors = FALSE
  )

  .gp3ml_as_feature_manifest(manifest)
}


#' Validate a Gazepoint feature-provenance manifest
#'
#' Validates the schema and declared scientific safeguards in a feature
#' manifest. Schema errors stop execution. Substantive concerns are
#' returned as structured `pass`, `review`, or `fail` checks.
#'
#' @param x A feature manifest created by
#'   [create_gazepoint_feature_manifest()] or a compatible data frame.
#'
#' @return An object of class
#'   `gazepoint_feature_manifest_validation` containing the overall
#'   status, complete checks, non-passing issues, and validated manifest.
#'
#' @details
#' A manifest fails when an intended predictor is declared as
#' outcome-derived, post-outcome, unavailable at prediction time, or an
#' identifier. It also fails when fold-local estimation is required but
#' preprocessing is declared outside the resampling fold.
#'
#' Unknown or incomplete provenance is returned for review rather than
#' treated as evidence that a safeguard was satisfied.
#'
#' @examples
#' manifest <- create_gazepoint_feature_manifest(
#'   features = "fixation_duration",
#'   scientific_source = "Gazepoint fixation export",
#'   source_table = "fixations",
#'   transformation = "Trial-level mean",
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#'
#' validate_gazepoint_feature_manifest(manifest)
#'
#' @export
validate_gazepoint_feature_manifest <- function(x) {
  manifest <- .gp3ml_as_feature_manifest(x)

  checks <- list()

  add_check <- function(
    feature,
    check_id,
    status,
    field,
    message,
    remediation) {
    checks[[length(checks) + 1L]] <<- data.frame(
      feature = feature,
      check_id = check_id,
      status = status,
      field = field,
      message = message,
      remediation = remediation,
      stringsAsFactors = FALSE
    )
  }

  for (index in seq_len(nrow(manifest))) {
    row <- manifest[index, , drop = FALSE]
    feature <- row$feature

    metadata_fields <- c(
      "scientific_source",
      "source_table",
      "transformation"
    )

    missing_metadata <- metadata_fields[
      vapply(
        row[metadata_fields],
        function(value) {
          .gp3ml_manifest_missing_text(value)
        },
        logical(1)
      )
    ]

    add_check(
      feature = feature,
      check_id = "provenance_metadata_complete",
      status = if (length(missing_metadata)) {
        "review"
      } else {
        "pass"
      },
      field = paste(missing_metadata, collapse = ", "),
      message = if (length(missing_metadata)) {
        "Required provenance metadata is incomplete."
      } else {
        "Required provenance metadata is complete."
      },
      remediation = if (length(missing_metadata)) {
        paste0(
          "Document the missing provenance fields before ",
          "predictive evaluation."
        )
      } else {
        "None."
      }
    )

    stage_unknown <- identical(
      row$availability_stage,
      "unknown"
    )

    add_check(
      feature = feature,
      check_id = "availability_stage_declared",
      status = if (stage_unknown) "review" else "pass",
      field = "availability_stage",
      message = if (stage_unknown) {
        "The feature availability stage is unknown."
      } else {
        "The feature availability stage is declared."
      },
      remediation = if (stage_unknown) {
        "Declare when the feature becomes available."
      } else {
        "None."
      }
    )

    prediction_available <- row$prediction_time_available

    add_check(
      feature = feature,
      check_id = "prediction_time_available",
      status = if (is.na(prediction_available)) {
        "review"
      } else if (!prediction_available) {
        "fail"
      } else {
        "pass"
      },
      field = "prediction_time_available",
      message = if (is.na(prediction_available)) {
        "Prediction-time availability has not been declared."
      } else if (!prediction_available) {
        "The feature is unavailable at the intended prediction time."
      } else {
        "The feature is available at the intended prediction time."
      },
      remediation = if (is.na(prediction_available)) {
        "Declare prediction-time availability."
      } else if (!prediction_available) {
        "Remove the feature from the intended predictor set."
      } else {
        "None."
      }
    )

    add_check(
      feature = feature,
      check_id = "outcome_derived",
      status = if (row$outcome_derived) "fail" else "pass",
      field = "outcome_derived",
      message = if (row$outcome_derived) {
        "The feature is declared as outcome-derived."
      } else {
        "The feature is not declared as outcome-derived."
      },
      remediation = if (row$outcome_derived) {
        "Remove outcome-derived features from the predictor set."
      } else {
        "None."
      }
    )

    stage_post_outcome <- identical(
      row$availability_stage,
      "post_outcome"
    )

    post_outcome_detected <- row$post_outcome ||
      stage_post_outcome

    add_check(
      feature = feature,
      check_id = "post_outcome",
      status = if (post_outcome_detected) "fail" else "pass",
      field = "post_outcome, availability_stage",
      message = if (post_outcome_detected) {
        "The feature is declared as post-outcome."
      } else {
        "The feature is not declared as post-outcome."
      },
      remediation = if (post_outcome_detected) {
        "Remove variables unavailable before the outcome."
      } else {
        "None."
      }
    )

    add_check(
      feature = feature,
      check_id = "identifier",
      status = if (row$identifier) "fail" else "pass",
      field = "identifier",
      message = if (row$identifier) {
        "The feature is declared as an identifier."
      } else {
        "The feature is not declared as an identifier."
      },
      remediation = if (row$identifier) {
        "Remove identifiers and row-location variables from predictors."
      } else {
        "None."
      }
    )

    scope_unknown <- identical(
      row$preprocessing_scope,
      "unknown"
    )

    add_check(
      feature = feature,
      check_id = "preprocessing_scope_declared",
      status = if (scope_unknown) "review" else "pass",
      field = "preprocessing_scope",
      message = if (scope_unknown) {
        "The preprocessing estimation scope is unknown."
      } else {
        "The preprocessing estimation scope is declared."
      },
      remediation = if (scope_unknown) {
        "Declare where data-dependent preprocessing was estimated."
      } else {
        "None."
      }
    )

    fold_required <- row$fold_local_required

    add_check(
      feature = feature,
      check_id = "fold_local_requirement_declared",
      status = if (is.na(fold_required)) "review" else "pass",
      field = "fold_local_required",
      message = if (is.na(fold_required)) {
        "The fold-local preprocessing requirement is unknown."
      } else {
        "The fold-local preprocessing requirement is declared."
      },
      remediation = if (is.na(fold_required)) {
        paste0(
          "Declare whether preprocessing must be estimated ",
          "inside each resampling fold."
        )
      } else {
        "None."
      }
    )

    scope_compatible <- if (is.na(fold_required)) {
      NA
    } else if (fold_required) {
      identical(
        row$preprocessing_scope,
        "resampling_fold"
      )
    } else {
      TRUE
    }

    add_check(
      feature = feature,
      check_id = "preprocessing_scope_compatible",
      status = if (is.na(scope_compatible)) {
        "review"
      } else if (!scope_compatible) {
        "fail"
      } else {
        "pass"
      },
      field = "preprocessing_scope, fold_local_required",
      message = if (is.na(scope_compatible)) {
        paste0(
          "Preprocessing compatibility cannot be assessed ",
          "without a fold-local requirement."
        )
      } else if (!scope_compatible) {
        paste0(
          "Fold-local estimation is required, but preprocessing ",
          "is not declared at resampling-fold scope."
        )
      } else {
        "The declared preprocessing scope is compatible."
      },
      remediation = if (is.na(scope_compatible)) {
        "Declare the fold-local preprocessing requirement."
      } else if (!scope_compatible) {
        paste0(
          "Estimate preprocessing separately inside each ",
          "resampling fold."
        )
      } else {
        "None."
      }
    )

    post_outcome_consistent <- identical(
      row$post_outcome,
      stage_post_outcome
    )

    add_check(
      feature = feature,
      check_id = "post_outcome_metadata_consistent",
      status = if (post_outcome_consistent) {
        "pass"
      } else {
        "review"
      },
      field = "post_outcome, availability_stage",
      message = if (post_outcome_consistent) {
        "Post-outcome declarations are internally consistent."
      } else {
        "Post-outcome declarations are internally inconsistent."
      },
      remediation = if (post_outcome_consistent) {
        "None."
      } else {
        paste0(
          "Reconcile `post_outcome` with ",
          "`availability_stage`."
        )
      }
    )

    availability_consistent <- !(
      isTRUE(prediction_available) &&
        post_outcome_detected
    )

    add_check(
      feature = feature,
      check_id = "availability_metadata_consistent",
      status = if (availability_consistent) {
        "pass"
      } else {
        "fail"
      },
      field = paste(
        "prediction_time_available,",
        "post_outcome, availability_stage"
      ),
      message = if (availability_consistent) {
        "Prediction-time availability metadata is consistent."
      } else {
        paste0(
          "The feature is marked available at prediction time ",
          "and also marked post-outcome."
        )
      },
      remediation = if (availability_consistent) {
        "None."
      } else {
        "Correct the availability declarations and remove unsafe features."
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
      status = overall_status,
      n_features = nrow(manifest),
      summary = summary,
      checks = checks,
      issues = issues,
      manifest = manifest,
      call = match.call()
    ),
    class = "gazepoint_feature_manifest_validation"
  )
}


#' Print feature-manifest validation
#'
#' @param x An object returned by
#'   [validate_gazepoint_feature_manifest()].
#' @param ... Additional arguments, currently unused.
#'
#' @return `x`, invisibly.
#'
#' @export
print.gazepoint_feature_manifest_validation <- function(x, ...) {
  cat("<gazepoint_feature_manifest_validation>\n")
  cat("Overall status: ", toupper(x$status), "\n", sep = "")
  cat("Features: ", x$n_features, "\n", sep = "")
  cat("Non-passing checks: ", nrow(x$issues), "\n", sep = "")

  print(
    x$summary,
    row.names = FALSE,
    right = FALSE
  )

  invisible(x)
}


#' Write a Gazepoint feature manifest or validation table to CSV
#'
#' Writes a feature manifest or one table from a validated manifest to a
#' UTF-8 CSV file. Existing files are not replaced unless explicitly
#' permitted.
#'
#' @param x A `gazepoint_feature_manifest`, compatible data frame, or
#'   object returned by [validate_gazepoint_feature_manifest()].
#' @param file A single output path ending in `.csv`.
#' @param table Table to export. One of `"manifest"`, `"issues"`, or
#'   `"checks"`. Plain manifest inputs support only `"manifest"`.
#' @param overwrite Logical. When `FALSE`, the default, an existing file
#'   causes an error.
#' @param na Character value used for missing values.
#'
#' @return The normalized output path, invisibly.
#'
#' @examples
#' manifest <- create_gazepoint_feature_manifest(
#'   features = "fixation_duration",
#'   scientific_source = "Gazepoint fixation export",
#'   source_table = "fixations",
#'   transformation = "Trial-level mean",
#'   availability_stage = "during_exposure",
#'   prediction_time_available = TRUE,
#'   preprocessing_scope = "none",
#'   fold_local_required = FALSE
#' )
#'
#' output <- tempfile(fileext = ".csv")
#'
#' write_gazepoint_feature_manifest_csv(
#'   manifest,
#'   output
#' )
#'
#' unlink(output)
#'
#' @export
write_gazepoint_feature_manifest_csv <- function(
    x,
    file,
    table = c("manifest", "issues", "checks"),
    overwrite = FALSE,
    na = "") {
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

  if (
    inherits(
      x,
      "gazepoint_feature_manifest_validation"
    )
  ) {
    output <- x[[table]]
  } else {
    manifest <- .gp3ml_as_feature_manifest(x)

    if (table != "manifest") {
      stop(
        paste0(
          "Plain manifest inputs support only ",
          "`table = \"manifest\"`."
        ),
        call. = FALSE
      )
    }

    output <- manifest
  }

  if (!is.data.frame(output)) {
    stop(
      sprintf(
        "Selected table `%s` is not available.",
        table
      ),
      call. = FALSE
    )
  }

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
