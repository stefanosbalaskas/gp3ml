#' Create nested grouped resampling from mature outer folds
#'
#' Inner folds are constructed only from each outer analysis partition and
#' preserve the declared participant/stimulus generalization target. The outer
#' assessment partition is never used for inner preprocessing or tuning.
#'
#' @param outer_folds A validated `gazepoint_group_folds` object.
#' @param inner_v Number of inner folds.
#' @param inner_repeats Number of inner repeats.
#' @param seed Base deterministic seed.
#' @param continue_on_error Whether infeasible outer folds are retained as
#'   failures instead of stopping immediately.
#'
#' @return A `gp3ml_nested_folds` object.
#' @examples
#' data <- simulate_gazepoint_governed_data(16L, 4L, 1L, 303L)
#' predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
#' manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
#' outer <- create_gazepoint_group_folds(
#'   data, "quality_status", predictors, manifest,
#'   "new_participants", "participant_id", "trial_id", "stimulus_id",
#'   v = 4L, repeats = 1L, seed = 303L
#' )
#' nested <- create_gazepoint_nested_folds(
#'   outer,
#'   inner_v = 3L,
#'   inner_repeats = 1L,
#'   seed = 303L
#' )
#' nested
#' @export
create_gazepoint_nested_folds <- function(
    outer_folds,
    inner_v = 3L,
    inner_repeats = 1L,
    seed = 1L,
    continue_on_error = FALSE) {
  if (!inherits(outer_folds, "gazepoint_group_folds")) {
    .gp3ml_stop("`outer_folds` must be a `gazepoint_group_folds` object.")
  }
  outer_validation <- validate_gazepoint_group_folds(outer_folds)
  if (!identical(outer_validation$status, "pass")) {
    .gp3ml_stop("Outer folds must pass validation before nesting.")
  }
  inner_v <- as.integer(inner_v)
  inner_repeats <- as.integer(inner_repeats)
  if (inner_v < 2L || inner_repeats < 1L) {
    .gp3ml_stop("`inner_v` must be at least two and `inner_repeats` positive.")
  }
  nested <- vector("list", length(outer_folds$folds))
  names(nested) <- names(outer_folds$folds)
  for (i in seq_along(outer_folds$folds)) {
    outer <- outer_folds$folds[[i]]
    inner_seed <- .gp3ml_seed_from(seed, "inner", outer$fold_id)
    captured <- .gp3ml_capture_conditions(
      create_gazepoint_group_folds(
        data = outer$analysis,
        outcome = outer_folds$metadata$outcome,
        predictors = outer_folds$metadata$predictors,
        feature_manifest = outer_folds$feature_manifest,
        generalization_target = outer_folds$metadata$generalization_target,
        participant_id = outer_folds$metadata$participant_id,
        trial_id = outer_folds$metadata$trial_id,
        stimulus_id = outer_folds$metadata$stimulus_id,
        v = inner_v,
        repeats = inner_repeats,
        seed = inner_seed,
        source_row_id = ".gp3ml_inner_source_row"
      )
    )
    failed <- !is.na(captured$error)
    nested[[i]] <- list(
      outer = outer,
      inner = if (failed) NULL else captured$value,
      outer_fold_id = outer$fold_id,
      status = if (failed) "fail" else "pass",
      error = captured$error,
      warnings = captured$warnings,
      seed = inner_seed
    )
    if (failed && !isTRUE(continue_on_error)) {
      .gp3ml_stop("Could not create inner folds for `%s`: %s", outer$fold_id, captured$error)
    }
  }
  object <- structure(
    list(
      folds = nested,
      outer_metadata = outer_folds$metadata,
      outer_feature_manifest = outer_folds$feature_manifest,
      inner_v = inner_v,
      inner_repeats = inner_repeats,
      seed = seed,
      outer_validation = outer_validation,
      call = match.call()
    ),
    class = "gp3ml_nested_folds"
  )
  object$audit <- audit_gazepoint_nested_resampling(object)
  object$validation <- validate_gazepoint_nested_folds(object)
  object
}

#' Audit nested grouped resampling for outer-assessment leakage
#'
#' @param x A `gp3ml_nested_folds` object.
#'
#' @return A `gp3ml_nested_resampling_audit`.
#' @export
audit_gazepoint_nested_resampling <- function(x) {
  if (!inherits(x, "gp3ml_nested_folds")) {
    .gp3ml_stop("`x` must be a `gp3ml_nested_folds` object.")
  }
  source_row_id <- x$outer_metadata$source_row_id
  rows <- lapply(x$folds, function(item) {
    if (item$status == "fail" || is.null(item$inner)) {
      return(data.frame(
        outer_fold_id = item$outer_fold_id,
        inner_fold_id = NA_character_,
        status = "fail",
        outer_assessment_overlap = NA_integer_,
        inner_analysis_assessment_overlap = NA_integer_,
        message = item$error,
        stringsAsFactors = FALSE
      ))
    }
    outer_assessment_rows <- item$outer$assessment[[source_row_id]]
    .gp3ml_bind_rows(lapply(item$inner$folds, function(inner) {
      inner_analysis_rows <- inner$analysis[[source_row_id]]
      inner_assessment_rows <- inner$assessment[[source_row_id]]
      inner_excluded_rows <- if (nrow(inner$excluded)) inner$excluded[[source_row_id]] else integer()
      outer_analysis_overlap <- length(intersect(outer_assessment_rows, inner_analysis_rows))
      outer_assessment_overlap <- length(intersect(outer_assessment_rows, inner_assessment_rows))
      outer_excluded_overlap <- length(intersect(outer_assessment_rows, inner_excluded_rows))
      inner_analysis_assessment_overlap <- length(intersect(inner_analysis_rows, inner_assessment_rows))
      inner_analysis_excluded_overlap <- length(intersect(inner_analysis_rows, inner_excluded_rows))
      inner_assessment_excluded_overlap <- length(intersect(inner_assessment_rows, inner_excluded_rows))
      overlap_values <- c(
        outer_analysis_overlap,
        outer_assessment_overlap,
        outer_excluded_overlap,
        inner_analysis_assessment_overlap,
        inner_analysis_excluded_overlap,
        inner_assessment_excluded_overlap
      )
      status <- if (any(overlap_values > 0L)) "fail" else if (
        identical(inner$leakage_audit$status, "review")
      ) "review" else "pass"
      data.frame(
        outer_fold_id = item$outer_fold_id,
        inner_fold_id = inner$fold_id,
        status = status,
        outer_assessment_inner_analysis_overlap = outer_analysis_overlap,
        outer_assessment_inner_assessment_overlap = outer_assessment_overlap,
        outer_assessment_inner_excluded_overlap = outer_excluded_overlap,
        inner_analysis_assessment_overlap = inner_analysis_assessment_overlap,
        inner_analysis_excluded_overlap = inner_analysis_excluded_overlap,
        inner_assessment_excluded_overlap = inner_assessment_excluded_overlap,
        outer_assessment_overlap = sum(c(
          outer_analysis_overlap,
          outer_assessment_overlap,
          outer_excluded_overlap
        )),
        message = if (status == "pass") {
          "No outer-assessment or inner-partition row overlap detected."
        } else {
          "Nested partition overlap requires review."
        },
        stringsAsFactors = FALSE
      )
    }))
  })
  checks <- .gp3ml_bind_rows(rows)
  structure(
    list(
      status = .gp3ml_worst_status(checks$status),
      checks = checks,
      issues = checks[checks$status != "pass", , drop = FALSE]
    ),
    class = "gp3ml_nested_resampling_audit"
  )
}

#' Validate nested grouped folds
#'
#' @param x A `gp3ml_nested_folds` object.
#'
#' @return A `gp3ml_nested_folds_validation` object.
#' @export
validate_gazepoint_nested_folds <- function(x) {
  if (!inherits(x, "gp3ml_nested_folds")) {
    .gp3ml_stop("`x` must be a `gp3ml_nested_folds` object.")
  }
  n_outer <- length(x$folds)
  n_inner_ready <- sum(vapply(x$folds, function(z) !is.null(z$inner), logical(1)))
  checks <- data.frame(
    check_id = c(
      "outer_folds_retained",
      "inner_folds_created",
      "outer_assessment_isolation",
      "generalization_target_preserved"
    ),
    status = c(
      if (n_outer == x$outer_metadata$n_folds_total) "pass" else "fail",
      if (n_inner_ready == n_outer) "pass" else "review",
      x$audit$status,
      if (all(vapply(x$folds, function(z) {
        is.null(z$inner) || identical(
          z$inner$metadata$generalization_target,
          x$outer_metadata$generalization_target
        )
      }, logical(1)))) "pass" else "fail"
    ),
    message = c(
      sprintf("Retained %d outer folds.", n_outer),
      sprintf("Created inner folds for %d of %d outer folds.", n_inner_ready, n_outer),
      "Inner resampling is audited against every outer assessment partition.",
      sprintf("Target: %s.", x$outer_metadata$generalization_target)
    ),
    stringsAsFactors = FALSE
  )
  structure(
    list(status = .gp3ml_worst_status(checks$status), checks = checks, issues = checks[checks$status != "pass", , drop = FALSE]),
    class = "gp3ml_nested_folds_validation"
  )
}


.gp3ml_nested_selection_rationale_default <- paste0(
  "Candidate selected by the ",
  "predeclared nested-resampling rule ",
  "and retained for human review."
)

#' Evaluate nested grouped resampling with inner governed tuning
#'
#' @param nested_folds A `gp3ml_nested_folds` object.
#' @param task Governed task.
#' @param tuning_grid Explicit tuning grid.
#' @param selection_metric Explicit inner selection metric.
#' @param direction Explicit selection direction.
#' @param predictors Optional predictors.
#' @param minimum_success_prop Minimum inner-fold success proportion.
#' @param tie_breakers Optional secondary metrics.
#' @param selection_rationale Human rationale recorded for each outer fold.
#' @param seed Base deterministic seed.
#' @param keep_models Whether outer fitted models are retained.
#' @param continue_on_error Whether failed outer folds remain in the result.
#'
#' @return A `gp3ml_nested_evaluation` object retaining inner tuning results,
#'   selections, outer predictions, metrics, and failures.
#' @export
evaluate_gazepoint_nested_resampling <- function(
    nested_folds,
    task,
    tuning_grid,
    selection_metric,
    direction,
    predictors = NULL,
    minimum_success_prop = 0.8,
    tie_breakers = NULL,
    selection_rationale = .gp3ml_nested_selection_rationale_default,
    seed = 1L,
    keep_models = FALSE,
    continue_on_error = TRUE) {
  if (!inherits(nested_folds, "gp3ml_nested_folds")) {
    .gp3ml_stop("`nested_folds` must be a `gp3ml_nested_folds` object.")
  }
  if (!inherits(tuning_grid, "gp3ml_tuning_grid")) {
    .gp3ml_stop("`tuning_grid` must be a `gp3ml_tuning_grid` object.")
  }
  assert_gp3ml_use_case(task)
  if (missing(direction)) {
    .gp3ml_stop("An explicit nested-selection `direction` is required.")
  }
  direction <- .gp3ml_validate_direction(selection_metric, direction)
  predictors <- predictors %||% nested_folds$outer_metadata$predictors
  source_row_id <- nested_folds$outer_metadata$source_row_id
  results <- vector("list", length(nested_folds$folds))
  names(results) <- names(nested_folds$folds)

  for (i in seq_along(nested_folds$folds)) {
    item <- nested_folds$folds[[i]]
    outer_seed <- .gp3ml_seed_from(seed, "outer", item$outer_fold_id)
    captured <- .gp3ml_capture_conditions({
      if (is.null(item$inner)) .gp3ml_stop("Inner folds are unavailable: %s", item$error)
      outer_task <- .gp3ml_redeclare_task(item$outer$analysis, task)
      tuned <- tune_gazepoint_model(
        folds = item$inner,
        task = outer_task,
        tuning_grid = tuning_grid,
        predictors = predictors,
        seed = .gp3ml_seed_from(outer_seed, "tune"),
        continue_on_error = TRUE,
        keep_evaluations = TRUE
      )
      selection <- select_gazepoint_model(
        tuned,
        metric = selection_metric,
        direction = direction,
        minimum_success_prop = minimum_success_prop,
        tie_breakers = tie_breakers,
        rationale = paste(selection_rationale, "Outer fold:", item$outer_fold_id)
      )
      candidate <- selection$candidate
      outer_model <- fit_gazepoint_model(
        data = item$outer$analysis,
        task = outer_task,
        predictors = predictors,
        engine = candidate$engine[[1L]],
        preprocessor_args = candidate$preprocessor_args[[1L]],
        engine_args = candidate$engine_args[[1L]],
        seed = .gp3ml_seed_from(outer_seed, "refit"),
        threshold = candidate$threshold[[1L]]
      )
      predictions <- .gp3ml_predictions_from_model(
        outer_model,
        item$outer$assessment,
        task,
        candidate$threshold[[1L]]
      )
      prediction_table <- .gp3ml_prediction_table(
        item$outer$assessment,
        task,
        item$outer,
        predictions,
        source_row_id,
        candidate_id = selection$candidate_id,
        stage = "outer_assessment"
      )
      metrics <- gazepoint_performance_metrics(
        task,
        truth = item$outer$assessment[[task$outcome]],
        prediction = predictions$prediction,
        probability = predictions$probability,
        threshold = candidate$threshold[[1L]]
      )
      list(
        tuning = tuned,
        selection = selection,
        model = outer_model,
        predictions = prediction_table,
        metrics = metrics,
        metrics_long = .gp3ml_metric_long(metrics, list(
          `repeat` = item$outer[["repeat"]],
          fold = item$outer$fold,
          fold_id = item$outer$fold_id,
          candidate_id = selection$candidate_id
        ))
      )
    })
    failed <- !is.na(captured$error)
    value <- captured$value
    results[[i]] <- list(
      outer_fold_id = item$outer_fold_id,
      `repeat` = item$outer[["repeat"]],
      fold = item$outer$fold,
      status = if (failed) "fail" else if (length(captured$warnings)) "review" else "pass",
      error = captured$error,
      warnings = captured$warnings,
      tuning = if (failed) NULL else value$tuning,
      selection = if (failed) NULL else value$selection,
      model = if (!failed && keep_models) value$model else NULL,
      predictions = if (failed) data.frame() else value$predictions,
      metrics = if (failed) data.frame() else value$metrics_long,
      excluded = item$outer$excluded,
      outer_analysis_hash = .gp3ml_hash_object(item$outer$analysis[[source_row_id]]),
      outer_assessment_hash = .gp3ml_hash_object(item$outer$assessment[[source_row_id]]),
      seed = outer_seed
    )
    if (failed && !continue_on_error) {
      .gp3ml_stop("Outer fold `%s` failed: %s", item$outer_fold_id, captured$error)
    }
  }

  status <- .gp3ml_bind_rows(lapply(results, function(z) data.frame(
    `repeat` = z[["repeat"]],
    fold = z$fold,
    fold_id = z$outer_fold_id,
    status = z$status,
    selected_candidate = if (is.null(z$selection)) NA_character_ else z$selection$candidate_id,
    n_predictions = nrow(z$predictions),
    warning_count = length(z$warnings),
    error = z$error,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )))
  object <- structure(
    list(
      results = results,
      predictions = .gp3ml_bind_rows(lapply(results, `[[`, "predictions")),
      metrics = .gp3ml_bind_rows(lapply(results, `[[`, "metrics")),
      excluded = .gp3ml_bind_rows(lapply(results, function(z) {
        if (!nrow(z$excluded)) return(NULL)
        out <- z$excluded
        out[["repeat"]] <- z[["repeat"]]
        out$fold <- z$fold
        out$fold_id <- z$outer_fold_id
        out
      })),
      fold_status = status,
      nested_folds_audit = nested_folds$audit,
      nested_folds_validation = nested_folds$validation,
      task = task,
      predictors = predictors,
      tuning_grid = tuning_grid,
      selection_metric = selection_metric,
      direction = direction,
      generalization_target = nested_folds$outer_metadata$generalization_target,
      seed = seed,
      keep_models = keep_models,
      call = match.call()
    ),
    class = "gp3ml_nested_evaluation"
  )
  object$validation <- validate_gazepoint_nested_evaluation(object)
  object
}

#' Validate a nested evaluation
#'
#' @param x A `gp3ml_nested_evaluation`.
#' @return A `gp3ml_nested_evaluation_validation`.
#' @export
validate_gazepoint_nested_evaluation <- function(x) {
  if (!inherits(x, "gp3ml_nested_evaluation")) {
    .gp3ml_stop("`x` must be a `gp3ml_nested_evaluation` object.")
  }
  selections <- vapply(x$results, function(z) !is.null(z$selection), logical(1))
  outer_only <- !nrow(x$predictions) || all(x$predictions$stage == "outer_assessment")
  checks <- data.frame(
    check_id = c(
      "nested_partition_audit",
      "outer_assessment_only",
      "selection_recorded",
      "failures_retained",
      "generalization_target_preserved"
    ),
    status = c(
      x$nested_folds_audit$status,
      if (outer_only) "pass" else "fail",
      if (all(selections)) "pass" else "review",
      "pass",
      if (identical(x$task$generalization_target, x$generalization_target)) "pass" else "fail"
    ),
    message = c(
      "Nested partitions retain the outer-assessment isolation audit.",
      "Reported predictions come only from outer assessment partitions.",
      sprintf("Recorded governed selections for %d of %d outer folds.", sum(selections), length(selections)),
      sprintf("Retained %d failed outer folds.", sum(x$fold_status$status == "fail")),
      sprintf("Target: %s.", x$generalization_target)
    ),
    stringsAsFactors = FALSE
  )
  structure(
    list(status = .gp3ml_worst_status(checks$status), checks = checks, issues = checks[checks$status != "pass", , drop = FALSE]),
    class = "gp3ml_nested_evaluation_validation"
  )
}

#' Write nested-resampling evaluation tables
#'
#' @param x A `gp3ml_nested_evaluation`.
#' @param directory Output directory.
#' @param prefix Filename prefix.
#' @param overwrite Whether existing files may be replaced.
#' @return Named paths, invisibly.
#' @export
write_gazepoint_nested_evaluation <- function(
    x,
    directory,
    prefix = "gazepoint_nested_evaluation",
    overwrite = FALSE) {
  if (!inherits(x, "gp3ml_nested_evaluation")) {
    .gp3ml_stop("`x` must be a `gp3ml_nested_evaluation` object.")
  }
  selections <- .gp3ml_bind_rows(lapply(x$results, function(z) {
    if (is.null(z$selection)) return(NULL)
    data.frame(
      fold_id = z$outer_fold_id,
      candidate_id = z$selection$candidate_id,
      metric = z$selection$primary_metric,
      direction = z$selection$direction,
      value = z$selection$primary_value,
      rationale = z$selection$rationale,
      stringsAsFactors = FALSE
    )
  }))
  invisible(.gp3ml_write_tables(
    list(
      fold_status = x$fold_status,
      selections = selections,
      predictions = x$predictions,
      metrics = x$metrics,
      excluded = x$excluded,
      validation = x$validation$checks,
      partition_audit = x$nested_folds_audit$checks
    ),
    directory,
    prefix,
    overwrite
  ))
}

#' @rdname create_gazepoint_nested_folds
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_nested_folds
#' @export
print.gp3ml_nested_folds <- function(x, ...) {
  cat("<gp3ml_nested_folds>\n")
  cat("  Outer folds: ", length(x$folds), "\n", sep = "")
  cat("  Inner v/repeats: ", x$inner_v, "/", x$inner_repeats, "\n", sep = "")
  cat("  Target: ", x$outer_metadata$generalization_target, "\n", sep = "")
  cat("  Audit: ", x$audit$status, "\n", sep = "")
  invisible(x)
}

#' @rdname audit_gazepoint_nested_resampling
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_nested_resampling_audit
#' @export
print.gp3ml_nested_resampling_audit <- function(x, ...) {
  cat("<gp3ml_nested_resampling_audit> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' @rdname validate_gazepoint_nested_folds
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_nested_folds_validation
#' @export
print.gp3ml_nested_folds_validation <- function(x, ...) {
  cat("<gp3ml_nested_folds_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' @rdname evaluate_gazepoint_nested_resampling
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_nested_evaluation
#' @export
print.gp3ml_nested_evaluation <- function(x, ...) {
  cat("<gp3ml_nested_evaluation>\n")
  cat("  Target: ", x$generalization_target, "\n", sep = "")
  cat("  Outer folds: ", nrow(x$fold_status), "\n", sep = "")
  cat("  Failed outer folds: ", sum(x$fold_status$status == "fail"), "\n", sep = "")
  cat("  Outer assessment predictions: ", nrow(x$predictions), "\n", sep = "")
  invisible(x)
}

#' @rdname validate_gazepoint_nested_evaluation
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_nested_evaluation_validation
#' @export
print.gp3ml_nested_evaluation_validation <- function(x, ...) {
  cat("<gp3ml_nested_evaluation_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}
