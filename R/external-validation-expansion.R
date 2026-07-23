#' Declare an external dataset and its independence status
#'
#' @param data Candidate external-validation data.
#' @param label Dataset label.
#' @param independent Explicit logical declaration of independence from model
#'   development and internal resampling.
#' @param origin Human-readable origin or collection source.
#' @param collection_period Optional collection period.
#' @param participant_id Participant identifier column.
#' @param stimulus_id Stimulus identifier column.
#' @param notes Optional notes.
#'
#' @return A `gp3ml_external_dataset_declaration`.
#' @examples
#' external <- simulate_gazepoint_governed_data(8L, 4L, 1L, 505L)
#' declaration <- declare_gazepoint_external_dataset(
#'   external,
#'   label = "synthetic_external_site",
#'   independent = TRUE,
#'   origin = "Independent deterministic synthetic site"
#' )
#' declaration
#' @export
declare_gazepoint_external_dataset <- function(
    data,
    label,
    independent,
    origin,
    collection_period = NULL,
    participant_id = "participant_id",
    stimulus_id = "stimulus_id",
    notes = character()) {
  .gp3ml_assert_data(data)
  if (length(label) != 1L || !nzchar(trimws(label))) .gp3ml_stop("`label` is required.")
  if (length(independent) != 1L || is.na(independent) || !is.logical(independent)) {
    .gp3ml_stop("`independent` must be explicitly TRUE or FALSE.")
  }
  if (length(origin) != 1L || !nzchar(trimws(origin))) .gp3ml_stop("`origin` is required.")
  for (column in c(participant_id, stimulus_id)) {
    if (!is.null(column) && length(column) && nzchar(column) && !column %in% names(data)) {
      .gp3ml_stop("Declared identifier `%s` is not present.", column)
    }
  }
  structure(
    list(
      label = trimws(label),
      independent = isTRUE(independent),
      origin = trimws(origin),
      collection_period = collection_period,
      participant_id = participant_id,
      stimulus_id = stimulus_id,
      n_rows = nrow(data),
      n_participants = if (!is.null(participant_id) && participant_id %in% names(data)) length(unique(data[[participant_id]])) else NA_integer_,
      n_stimuli = if (!is.null(stimulus_id) && stimulus_id %in% names(data)) length(unique(data[[stimulus_id]])) else NA_integer_,
      data_hash = .gp3ml_hash_object(data),
      notes = as.character(notes),
      declared_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    class = "gp3ml_external_dataset_declaration"
  )
}

.gp3ml_schema_comparison <- function(development_data, external_data, predictors) {
  all_columns <- union(names(development_data), names(external_data))
  .gp3ml_bind_rows(lapply(all_columns, function(name) {
    development_present <- name %in% names(development_data)
    external_present <- name %in% names(external_data)
    development_class <- if (development_present) paste(class(development_data[[name]]), collapse = "/") else NA_character_
    external_class <- if (external_present) paste(class(external_data[[name]]), collapse = "/") else NA_character_
    data.frame(
      variable = name,
      predictor = name %in% predictors,
      development_present = development_present,
      external_present = external_present,
      development_class = development_class,
      external_class = external_class,
      class_match = development_present && external_present && identical(development_class, external_class),
      development_missing_prop = if (development_present) mean(is.na(development_data[[name]])) else NA_real_,
      external_missing_prop = if (external_present) mean(is.na(external_data[[name]])) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
}

.gp3ml_group_transportability <- function(development_data, external_data, column, unit) {
  if (is.null(column) || !nzchar(column) || !column %in% names(development_data) || !column %in% names(external_data)) {
    return(data.frame(
      unit = unit,
      identifier = column %||% NA_character_,
      development_groups = NA_integer_,
      external_groups = NA_integer_,
      overlapping_groups = NA_integer_,
      external_novel_groups = NA_integer_,
      external_coverage_prop = NA_real_,
      status = "not_available",
      stringsAsFactors = FALSE
    ))
  }
  development_groups <- unique(as.character(development_data[[column]]))
  external_groups <- unique(as.character(external_data[[column]]))
  overlap <- intersect(development_groups, external_groups)
  novel <- setdiff(external_groups, development_groups)
  data.frame(
    unit = unit,
    identifier = column,
    development_groups = length(development_groups),
    external_groups = length(external_groups),
    overlapping_groups = length(overlap),
    external_novel_groups = length(novel),
    external_coverage_prop = if (length(external_groups)) length(novel) / length(external_groups) else NA_real_,
    status = if (length(overlap)) "review" else "pass",
    stringsAsFactors = FALSE
  )
}

.gp3ml_prevalence_shift <- function(task, development_data, external_data) {
  if (task$task_type != "classification") return(data.frame())
  development_rate <- mean(as.character(development_data[[task$outcome]]) == task$positive, na.rm = TRUE)
  external_rate <- mean(as.character(external_data[[task$outcome]]) == task$positive, na.rm = TRUE)
  data.frame(
    positive = task$positive,
    development_prevalence = development_rate,
    external_prevalence = external_rate,
    absolute_shift = external_rate - development_rate,
    relative_shift = if (development_rate == 0) NA_real_ else external_rate / development_rate,
    stringsAsFactors = FALSE
  )
}

.gp3ml_development_metric_summary <- function(development_evaluation) {
  if (is.null(development_evaluation)) return(data.frame())
  if (inherits(development_evaluation, c("gp3ml_resample_evaluation", "gp3ml_nested_evaluation"))) {
    metrics <- development_evaluation$metrics
    return(.gp3ml_bind_rows(lapply(unique(metrics$metric), function(metric) {
      values <- metrics$value[metrics$metric == metric]
      data.frame(metric = metric, development_estimate = mean(values, na.rm = TRUE), stringsAsFactors = FALSE)
    })))
  }
  if (is.data.frame(development_evaluation)) {
    numeric_names <- names(development_evaluation)[vapply(development_evaluation, is.numeric, logical(1))]
    return(data.frame(
      metric = numeric_names,
      development_estimate = vapply(numeric_names, function(name) mean(development_evaluation[[name]], na.rm = TRUE), numeric(1)),
      stringsAsFactors = FALSE
    ))
  }
  .gp3ml_stop("`development_evaluation` must be a grouped evaluation or metric data frame.")
}

#' Evaluate external transportability and validation status
#'
#' An internal holdout or a dataset explicitly declared non-independent is
#' labelled `not_externally_validated`; it cannot generate an external-
#' validation claim.
#'
#' @param model Fitted governed model.
#' @param development_data Data used to characterize development schema and
#'   group coverage.
#' @param external_data Candidate external data. May be `NULL` to create an
#'   explicit not-validated status.
#' @param declaration External dataset declaration. Required when external data
#'   are supplied.
#' @param development_evaluation Optional grouped development evaluation.
#' @param threshold Classification threshold.
#' @param bootstrap Calibration bootstrap replicates.
#' @param seed Deterministic seed.
#'
#' @return A `gp3ml_transportability_report` object.
#' @export
evaluate_gazepoint_external_transportability <- function(
    model,
    development_data,
    external_data = NULL,
    declaration = NULL,
    development_evaluation = NULL,
    threshold = model$threshold,
    bootstrap = 200L,
    seed = 1L) {
  if (!inherits(model, "gp3ml_model")) .gp3ml_stop("`model` must be a fitted gp3ml model.")
  .gp3ml_assert_data(development_data)
  if (is.null(external_data)) {
    report <- structure(
      list(
        status = "not_externally_validated",
        reason = "No independent external dataset was supplied.",
        declaration = declaration,
        declaration_hash_matches = NA,
        metrics = data.frame(),
        performance_comparison = data.frame(),
        calibration_drift = data.frame(),
        prevalence_shift = data.frame(),
        schema = data.frame(),
        group_coverage = data.frame(),
        predictor_shift = data.frame(),
        validation = NULL,
        task = model$task,
        model_engine = model$engine,
        limitations = "Internal holdout or grouped resampling does not establish external validation."
      ),
      class = "gp3ml_transportability_report"
    )
    report$validation_summary <- validate_gazepoint_transportability(report)
    return(report)
  }
  .gp3ml_assert_data(external_data)
  if (!inherits(declaration, "gp3ml_external_dataset_declaration")) {
    .gp3ml_stop("Supply a `gp3ml_external_dataset_declaration` for external data.")
  }
  schema <- .gp3ml_schema_comparison(development_data, external_data, model$predictors)
  declaration_hash_matches <- identical(
    declaration$data_hash,
    .gp3ml_hash_object(external_data)
  )
  outcome_row <- schema[schema$variable == model$task$outcome, , drop = FALSE]
  outcome_available <- nrow(outcome_row) == 1L && isTRUE(outcome_row$external_present[[1L]])
  outcome_type_compatible <- outcome_available && isTRUE(outcome_row$class_match[[1L]])
  missing_predictors <- schema$variable[schema$predictor & !schema$external_present]
  type_mismatches <- schema$variable[schema$predictor & schema$external_present & !schema$class_match]
  group_coverage <- .gp3ml_bind_rows(list(
    .gp3ml_group_transportability(development_data, external_data, model$task$participant_id, "participant"),
    .gp3ml_group_transportability(development_data, external_data, model$task$stimulus_id, "stimulus")
  ))
  independence_issues <- group_coverage$overlapping_groups
  independence_issues <- independence_issues[is.finite(independence_issues)]
  if (!declaration_hash_matches) {
    status <- "external_declaration_mismatch"
    reason <- "The external data no longer match the dataset fingerprint recorded in the declaration."
  } else if (!declaration$independent) {
    status <- "not_externally_validated"
    reason <- "The supplied dataset was explicitly declared non-independent."
  } else if (!outcome_available || !outcome_type_compatible ||
             length(missing_predictors) || length(type_mismatches)) {
    status <- "incompatible_external_schema"
    reason <- paste(
      if (!outcome_available) paste("Missing outcome:", model$task$outcome) else NULL,
      if (outcome_available && !outcome_type_compatible) paste("Outcome type mismatch:", model$task$outcome) else NULL,
      if (length(missing_predictors)) paste("Missing predictors:", paste(missing_predictors, collapse = ", ")) else NULL,
      if (length(type_mismatches)) paste("Predictor type mismatches:", paste(type_mismatches, collapse = ", ")) else NULL,
      collapse = "; "
    )
  } else if (length(independence_issues) && any(independence_issues > 0L)) {
    status <- "external_independence_requires_review"
    reason <- "Declared identifier values overlap between development and external data."
  } else {
    status <- "externally_validated"
    reason <- "The explicitly independent dataset passed schema and identifier-overlap gates."
  }

  validation <- NULL
  metrics <- data.frame()
  predictor_shift <- data.frame()
  calibration_drift <- data.frame()
  performance_comparison <- data.frame()
  prevalence_shift <- if (outcome_available && outcome_type_compatible) {
    .gp3ml_prevalence_shift(model$task, development_data, external_data)
  } else {
    data.frame()
  }
  if (status %in% c("externally_validated", "external_independence_requires_review")) {
    validation <- evaluate_external_validation(
      model,
      external_data,
      label = declaration$label,
      threshold = threshold,
      bootstrap = bootstrap,
      seed = seed
    )
    metrics <- validation$metrics
    predictor_shift <- validation$shift
    development_metrics <- .gp3ml_development_metric_summary(development_evaluation)
    external_long <- .gp3ml_metric_long(metrics)
    if (nrow(external_long)) {
      names(external_long)[names(external_long) == "value"] <- "external_estimate"
      performance_comparison <- merge(
        development_metrics,
        external_long[c("metric", "external_estimate")],
        by = "metric",
        all = TRUE,
        sort = FALSE
      )
      performance_comparison$difference <- performance_comparison$external_estimate - performance_comparison$development_estimate
    }
    if (model$task$task_type == "classification" && !is.null(validation$calibration)) {
      external_calibration <- validation$calibration$summary
      names(external_calibration) <- paste0("external_", names(external_calibration))
      calibration_drift <- external_calibration
      if (!is.null(development_evaluation) && inherits(development_evaluation, "gp3ml_resample_evaluation")) {
        calibration_summaries <- lapply(development_evaluation$fold_results, function(z) {
          if (is.null(z$calibration)) return(NULL)
          z$calibration$summary
        })
        development_calibration <- .gp3ml_bind_rows(calibration_summaries)
        if (nrow(development_calibration)) {
          for (name in names(development_calibration)) {
            calibration_drift[[paste0("development_", name)]] <- mean(development_calibration[[name]], na.rm = TRUE)
            calibration_drift[[paste0("drift_", name)]] <- calibration_drift[[paste0("external_", name)]] - calibration_drift[[paste0("development_", name)]]
          }
        }
      }
    }
  }

  report <- structure(
    list(
      status = status,
      reason = reason,
      declaration = declaration,
      declaration_hash_matches = declaration_hash_matches,
      metrics = metrics,
      performance_comparison = performance_comparison,
      calibration_drift = calibration_drift,
      prevalence_shift = prevalence_shift,
      schema = schema,
      group_coverage = group_coverage,
      predictor_shift = predictor_shift,
      validation = validation,
      task = model$task,
      model_engine = model$engine,
      development_hash = .gp3ml_hash_object(development_data[c(model$task$outcome, model$predictors)]),
      external_hash = declaration$data_hash,
      limitations = c(
        "External validation is specific to the declared dataset, outcome, predictors, and collection context.",
        "Transportability beyond the observed external context requires additional evidence."
      ),
      call = match.call()
    ),
    class = "gp3ml_transportability_report"
  )
  report$validation_summary <- validate_gazepoint_transportability(report)
  report
}

#' Validate an external transportability report
#'
#' @param x A `gp3ml_transportability_report`.
#' @return A `gp3ml_transportability_validation`.
#' @export
validate_gazepoint_transportability <- function(x) {
  if (!inherits(x, "gp3ml_transportability_report")) {
    .gp3ml_stop("`x` must be a `gp3ml_transportability_report` object.")
  }
  externally_validated <- identical(x$status, "externally_validated")
  checks <- data.frame(
    check_id = c(
      "independence_declared",
      "declaration_matches_data",
      "outcome_available",
      "outcome_type_compatible",
      "predictors_available",
      "predictor_types_compatible",
      "identifier_overlap",
      "external_validation_status_explicit"
    ),
    status = c(
      if (is.null(x$declaration)) "review" else if (x$declaration$independent) "pass" else "fail",
      if (is.null(x$declaration)) "review" else if (isTRUE(x$declaration_hash_matches)) "pass" else "fail",
      if (!nrow(x$schema)) "review" else if (any(x$schema$variable == x$task$outcome & x$schema$external_present)) "pass" else "fail",
      if (!nrow(x$schema)) "review" else if (any(x$schema$variable == x$task$outcome & x$schema$class_match)) "pass" else "fail",
      if (!nrow(x$schema)) "review" else if (any(x$schema$predictor & !x$schema$external_present)) "fail" else "pass",
      if (!nrow(x$schema)) "review" else if (any(x$schema$predictor & x$schema$external_present & !x$schema$class_match)) "fail" else "pass",
      if (!nrow(x$group_coverage)) "review" else if (any(x$group_coverage$status == "review")) "review" else "pass",
      if (nzchar(x$status)) "pass" else "fail"
    ),
    message = c(
      if (is.null(x$declaration)) "No external independence declaration is attached." else paste("Independent:", x$declaration$independent),
      "The supplied external data must match the declaration fingerprint.",
      "The observed outcome must be present in the external schema.",
      "The external outcome class must match the development schema.",
      "All model predictors must be available in the external schema.",
      "External predictor classes must match the development schema.",
      "Participant and stimulus identifier overlap is reviewed explicitly.",
      paste("Status:", x$status, "-", x$reason)
    ),
    stringsAsFactors = FALSE
  )
  status <- if (externally_validated) .gp3ml_worst_status(checks$status) else if (x$status == "not_externally_validated") "review" else .gp3ml_worst_status(checks$status)
  structure(
    list(status = status, checks = checks, issues = checks[checks$status != "pass", , drop = FALSE]),
    class = "gp3ml_transportability_validation"
  )
}

#' Write an expanded transportability report
#'
#' @param report A `gp3ml_transportability_report`.
#' @param path Destination Markdown path.
#' @param overwrite Whether an existing file may be replaced.
#' @return The destination path, invisibly.
#' @export
write_gazepoint_transportability_report <- function(report, path, overwrite = FALSE) {
  if (!inherits(report, "gp3ml_transportability_report")) {
    .gp3ml_stop("`report` must be a `gp3ml_transportability_report` object.")
  }
  if (file.exists(path) && !overwrite) .gp3ml_stop("File exists: %s.", path)
  lines <- c(
    "# Gazepoint external validation and transportability", "",
    paste0("Status: **", report$status, "**"), "",
    report$reason, "",
    "## Declaration", "",
    if (is.null(report$declaration)) "No independent external dataset was declared." else c(
      paste0("- Label: ", report$declaration$label),
      paste0("- Independent: ", report$declaration$independent),
      paste0("- Origin: ", report$declaration$origin),
      paste0("- Rows: ", report$declaration$n_rows)
    ), "",
    "## Development versus external performance", "",
    .gp3ml_markdown_table(report$performance_comparison), "",
    "## Calibration drift", "",
    .gp3ml_markdown_table(report$calibration_drift), "",
    "## Class-prevalence shift", "",
    .gp3ml_markdown_table(report$prevalence_shift), "",
    "## Predictor availability and schema", "",
    .gp3ml_markdown_table(report$schema), "",
    "## Participant and stimulus coverage", "",
    .gp3ml_markdown_table(report$group_coverage), "",
    "## Predictor shift", "",
    .gp3ml_markdown_table(report$predictor_shift), "",
    "## Limitations", "",
    paste0("- ", report$limitations), "",
    "## Interpretation boundary", "",
    "An internal holdout is not external validation. This report applies only to explicitly observed, non-sensitive outcomes and the declared external context."
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

#' @rdname declare_gazepoint_external_dataset
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_external_dataset_declaration
#' @export
print.gp3ml_external_dataset_declaration <- function(x, ...) {
  cat("<gp3ml_external_dataset_declaration>\n")
  cat("  Label: ", x$label, "\n", sep = "")
  cat("  Independent: ", x$independent, "\n", sep = "")
  cat("  Origin: ", x$origin, "\n", sep = "")
  cat("  Rows: ", x$n_rows, "\n", sep = "")
  invisible(x)
}

#' @rdname evaluate_gazepoint_external_transportability
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_transportability_report
#' @export
print.gp3ml_transportability_report <- function(x, ...) {
  cat("<gp3ml_transportability_report>\n")
  cat("  Status: ", x$status, "\n", sep = "")
  cat("  Reason: ", x$reason, "\n", sep = "")
  if (nrow(x$performance_comparison)) print(x$performance_comparison, row.names = FALSE)
  invisible(x)
}

#' @rdname validate_gazepoint_transportability
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_transportability_validation
#' @export
print.gp3ml_transportability_validation <- function(x, ...) {
  cat("<gp3ml_transportability_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}
