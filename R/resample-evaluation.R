#' Evaluate a governed model specification across materialized grouped folds
#'
#' Fits preprocessing and the requested model only on each fold's analysis
#' partition, predicts only on the corresponding assessment partition, retains
#' excluded rows, and records fold-level metrics, leakage audits, warnings, and
#' failures. Row-level predictions are never relabelled as participant- or
#' stimulus-level estimates.
#'
#' @param folds A mature `gazepoint_group_folds` object containing materialized
#'   folds under `folds$folds`.
#' @param task A governed `gp3ml_task` compatible with the fold metadata.
#' @param predictors Optional predictor names. Defaults to the fold metadata.
#' @param engine Model engine name or governed custom engine.
#' @param preprocessor_args Arguments passed to [fit_gazepoint_preprocessor()].
#' @param engine_args Arguments passed to [fit_gazepoint_model()].
#' @param threshold Classification threshold.
#' @param seed Base deterministic seed.
#' @param assess_calibration Whether to calculate assessment-fold calibration
#'   summaries for classification tasks.
#' @param calibration_bins Number of reliability bins.
#' @param calibration_bootstrap Calibration bootstrap replicates. Use zero in
#'   fast smoke tests.
#' @param keep_models Whether fitted fold models are retained.
#' @param continue_on_error Whether later folds continue after a failed fold.
#'
#' @return A `gp3ml_resample_evaluation` object.
#' @examples
#' data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 101L)
#' predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
#' manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
#' folds <- create_gazepoint_group_folds(
#'   data = data,
#'   outcome = "quality_status",
#'   predictors = predictors,
#'   feature_manifest = manifest,
#'   generalization_target = "new_participants",
#'   participant_id = "participant_id",
#'   trial_id = "trial_id",
#'   stimulus_id = "stimulus_id",
#'   v = 3L,
#'   repeats = 1L,
#'   seed = 101L
#' )
#' task <- create_gazepoint_synthetic_task(
#'   data,
#'   "recording_quality",
#'   "new_participants"
#' )
#' evaluation <- evaluate_gazepoint_group_folds(
#'   folds,
#'   task,
#'   predictors = predictors,
#'   engine = "glm",
#'   seed = 101L
#' )
#' evaluation
#' @export
evaluate_gazepoint_group_folds <- function(
    folds,
    task,
    predictors = NULL,
    engine = NULL,
    preprocessor_args = list(),
    engine_args = list(),
    threshold = 0.5,
    seed = 1L,
    assess_calibration = FALSE,
    calibration_bins = 10L,
    calibration_bootstrap = 0L,
    keep_models = FALSE,
    continue_on_error = TRUE) {
  if (!inherits(folds, "gazepoint_group_folds")) {
    .gp3ml_stop("`folds` must be a `gazepoint_group_folds` object.")
  }
  assert_gp3ml_use_case(task)
  validation <- validate_gazepoint_group_folds(folds)
  if (!identical(validation$status, "pass")) {
    .gp3ml_stop("The grouped fold object must pass validation before evaluation.")
  }
  if (!identical(task$outcome, folds$metadata$outcome)) {
    .gp3ml_stop("The task outcome does not match the fold outcome.")
  }
  if (!identical(task$generalization_target, folds$metadata$generalization_target)) {
    .gp3ml_stop("The task generalization target does not match the folds.")
  }
  predictors <- predictors %||% folds$metadata$predictors
  if (!length(predictors)) .gp3ml_stop("At least one predictor is required.")
  if (!all(predictors %in% folds$metadata$predictors)) {
    .gp3ml_stop("Evaluation predictors must be declared in the fold metadata.")
  }
  if (!is.list(preprocessor_args) || !is.list(engine_args)) {
    .gp3ml_stop("`preprocessor_args` and `engine_args` must be lists.")
  }
  source_row_id <- folds$metadata$source_row_id
  fold_results <- vector("list", length(folds$folds))
  names(fold_results) <- names(folds$folds)

  for (i in seq_along(folds$folds)) {
    fold_object <- folds$folds[[i]]
    fold_seed <- .gp3ml_seed_from(seed, fold_object[["repeat"]], fold_object$fold)
    condition_result <- .gp3ml_capture_conditions({
      analysis_task <- .gp3ml_redeclare_task(fold_object$analysis, task)
      role_validation <- validate_gazepoint_ml_roles(
        data = fold_object$analysis,
        task = analysis_task,
        predictors = predictors,
        feature_manifest = folds$feature_manifest
      )
      if (identical(role_validation$status, "fail")) {
        .gp3ml_stop("Fold `%s` failed role validation.", fold_object$fold_id)
      }
      if (!is.null(fold_object$leakage_audit$status) &&
          identical(fold_object$leakage_audit$status, "fail")) {
        .gp3ml_stop("Fold `%s` failed its stored leakage audit.", fold_object$fold_id)
      }
      model <- fit_gazepoint_model(
        data = fold_object$analysis,
        task = analysis_task,
        predictors = predictors,
        engine = engine,
        preprocessor_args = preprocessor_args,
        engine_args = engine_args,
        seed = fold_seed,
        threshold = threshold
      )
      predictions <- .gp3ml_predictions_from_model(
        model,
        fold_object$assessment,
        task,
        threshold
      )
      prediction_table <- .gp3ml_prediction_table(
        data = fold_object$assessment,
        task = task,
        fold_object = fold_object,
        predictions = predictions,
        source_row_id = source_row_id
      )
      metrics <- gazepoint_performance_metrics(
        task = task,
        truth = fold_object$assessment[[task$outcome]],
        prediction = predictions$prediction,
        probability = predictions$probability,
        threshold = threshold
      )
      identifiers <- list(
        `repeat` = fold_object[["repeat"]],
        fold = fold_object$fold,
        fold_id = fold_object$fold_id
      )
      metrics_long <- .gp3ml_metric_long(metrics, identifiers)
      calibration <- NULL
      if (isTRUE(assess_calibration) && task$task_type == "classification") {
        calibration <- assess_gazepoint_calibration(
          truth = fold_object$assessment[[task$outcome]],
          probability = predictions$probability,
          positive = task$positive,
          bins = calibration_bins,
          bootstrap = as.integer(calibration_bootstrap),
          seed = .gp3ml_seed_from(fold_seed, "calibration")
        )
        calibration_metrics <- data.frame(
          ece = calibration$summary$ece,
          calibration_intercept_abs = abs(calibration$summary$intercept),
          calibration_slope_abs_error = abs(calibration$summary$slope - 1),
          stringsAsFactors = FALSE
        )
        metrics_long <- .gp3ml_bind_rows(list(
          metrics_long,
          .gp3ml_metric_long(calibration_metrics, identifiers)
        ))
      }
      list(
        model = model,
        predictions = prediction_table,
        metrics = metrics,
        metrics_long = metrics_long,
        calibration = calibration,
        role_validation = role_validation,
        analysis_hash = .gp3ml_hash_object(
          fold_object$analysis[c(task$outcome, predictors)]
        ),
        assessment_hash = .gp3ml_hash_object(
          fold_object$assessment[c(task$outcome, predictors)]
        )
      )
    })

    failed <- !is.na(condition_result$error)
    value <- condition_result$value
    status <- if (failed) {
      "fail"
    } else if (length(condition_result$warnings) ||
               identical(fold_object$leakage_audit$status, "review") ||
               identical(value$role_validation$status, "review")) {
      "review"
    } else {
      "pass"
    }
    fold_results[[i]] <- list(
      `repeat` = fold_object[["repeat"]],
      fold = fold_object$fold,
      fold_id = fold_object$fold_id,
      status = status,
      error = condition_result$error,
      warnings = condition_result$warnings,
      messages = condition_result$messages,
      n_analysis = nrow(fold_object$analysis),
      n_assessment = nrow(fold_object$assessment),
      n_excluded = nrow(fold_object$excluded),
      assessment_class_support = table(
        fold_object$assessment[[task$outcome]],
        useNA = "ifany"
      ),
      analysis_class_support = table(
        fold_object$analysis[[task$outcome]],
        useNA = "ifany"
      ),
      leakage_status = fold_object$leakage_audit$status %||% NA_character_,
      leakage_audit = fold_object$leakage_audit,
      model = if (!failed && isTRUE(keep_models)) value$model else NULL,
      predictions = if (!failed) value$predictions else data.frame(),
      metrics = if (!failed) value$metrics else data.frame(),
      metrics_long = if (!failed) value$metrics_long else data.frame(),
      calibration = if (!failed) value$calibration else NULL,
      role_validation = if (!failed) value$role_validation else NULL,
      analysis_hash = if (!failed) value$analysis_hash else NA_character_,
      assessment_hash = if (!failed) value$assessment_hash else NA_character_,
      excluded = fold_object$excluded
    )
    if (failed && !isTRUE(continue_on_error)) {
      .gp3ml_stop(
        "Fold `%s` failed: %s",
        fold_object$fold_id,
        condition_result$error
      )
    }
  }

  status_rows <- lapply(fold_results, function(result) {
    data.frame(
      `repeat` = result[["repeat"]],
      fold = result$fold,
      fold_id = result$fold_id,
      status = result$status,
      leakage_status = result$leakage_status,
      n_analysis = result$n_analysis,
      n_assessment = result$n_assessment,
      n_excluded = result$n_excluded,
      n_predictions = nrow(result$predictions),
      n_missing_predictions = if (nrow(result$predictions)) {
        sum(result$predictions$prediction_missing)
      } else {
        result$n_assessment
      },
      warning_count = length(result$warnings),
      error = result$error,
      warnings = paste(result$warnings, collapse = " | "),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })

  object <- structure(
    list(
      fold_results = fold_results,
      predictions = .gp3ml_bind_rows(lapply(fold_results, `[[`, "predictions")),
      metrics = .gp3ml_bind_rows(lapply(fold_results, `[[`, "metrics_long")),
      fold_status = .gp3ml_bind_rows(status_rows),
      excluded = .gp3ml_bind_rows(lapply(fold_results, function(result) {
        if (!nrow(result$excluded)) return(NULL)
        out <- result$excluded
        out[["repeat"]] <- result[["repeat"]]
        out$fold <- result$fold
        out$fold_id <- result$fold_id
        out
      })),
      task = task,
      predictors = predictors,
      engine = if (inherits(engine, "gp3ml_engine")) engine$name else engine %||%
        if (task$task_type == "classification") "glm" else "lm",
      preprocessor_args = preprocessor_args,
      engine_args = engine_args,
      threshold = threshold,
      seed = seed,
      generalization_target = folds$metadata$generalization_target,
      folds_metadata = folds$metadata,
      folds_audit = folds$audit,
      folds_validation = validation,
      keep_models = keep_models,
      call = match.call()
    ),
    class = "gp3ml_resample_evaluation"
  )
  object$validation <- validate_gazepoint_resample_evaluation(object)
  object
}

#' Collect predictions from a grouped-fold evaluation
#'
#' @param x A `gp3ml_resample_evaluation`.
#' @param include_failed Whether failed folds are represented by explicit status
#'   rows when they produced no predictions.
#'
#' @return A data frame of row-level assessment predictions with fold labels.
#' @export
collect_gazepoint_fold_predictions <- function(x, include_failed = TRUE) {
  if (!inherits(x, "gp3ml_resample_evaluation")) {
    .gp3ml_stop("`x` must be a `gp3ml_resample_evaluation` object.")
  }
  out <- x$predictions
  if (isTRUE(include_failed)) {
    failed <- x$fold_status[x$fold_status$status == "fail", , drop = FALSE]
    if (nrow(failed)) {
      placeholders <- failed[c("repeat", "fold", "fold_id", "status", "error")]
      placeholders$stage <- "assessment"
      placeholders$prediction_missing <- TRUE
      out <- .gp3ml_bind_rows(list(out, placeholders))
    }
  }
  out
}

#' Summarize repeated grouped-resampling performance
#'
#' @param x A `gp3ml_resample_evaluation`.
#' @param aggregation Either fold-distribution summaries or pooled row-level
#'   predictions. Pooled rows are explicitly labelled and do not change the
#'   generalization unit.
#' @param conf_level Confidence level for fold-distribution quantiles.
#'
#' @return A `gp3ml_resample_performance_summary` object.
#' @export
summarize_gazepoint_resample_performance <- function(
    x,
    aggregation = c("fold_distribution", "pooled_rows"),
    conf_level = 0.95) {
  if (!inherits(x, c("gp3ml_resample_evaluation", "gp3ml_nested_evaluation"))) {
    .gp3ml_stop("`x` must be a grouped or nested gp3ml evaluation object.")
  }
  aggregation <- match.arg(aggregation)
  if (inherits(x, "gp3ml_nested_evaluation") && aggregation == "pooled_rows") {
    .gp3ml_stop("Nested evaluations use candidate-specific thresholds; summarize their outer-fold distribution instead of pooling rows.")
  }
  if (aggregation == "fold_distribution") {
    metrics <- x$metrics
    metric_names <- unique(metrics$metric)
    summary <- .gp3ml_bind_rows(lapply(metric_names, function(metric) {
      values <- metrics$value[metrics$metric == metric]
      interval <- .gp3ml_quantile_interval(values, conf_level)
      data.frame(
        metric = metric,
        direction = .gp3ml_roadmap_metric_direction(metric),
        n_folds = sum(is.finite(values)),
        mean = mean(values, na.rm = TRUE),
        median = stats::median(values, na.rm = TRUE),
        sd = stats::sd(values, na.rm = TRUE),
        lower = interval[[1L]],
        upper = interval[[2L]],
        stringsAsFactors = FALSE
      )
    }))
  } else {
    predictions <- x$predictions
    if (!nrow(predictions)) .gp3ml_stop("No predictions are available to pool.")
    if (x$task$task_type == "classification") {
      metrics <- gazepoint_performance_metrics(
        x$task,
        truth = predictions$truth,
        prediction = predictions$prediction,
        probability = predictions$probability,
        threshold = x$threshold
      )
    } else {
      metrics <- gazepoint_performance_metrics(
        x$task,
        truth = as.numeric(predictions$truth),
        prediction = as.numeric(predictions$prediction),
        threshold = x$threshold
      )
    }
    summary <- .gp3ml_metric_long(metrics)
    summary$aggregation_warning <- paste(
      "Pooled row-level metrics summarize assessment predictions and are not",
      "participant- or stimulus-level estimates."
    )
  }
  structure(
    list(
      summary = summary,
      aggregation = aggregation,
      conf_level = conf_level,
      generalization_target = x$generalization_target,
      n_folds = nrow(x$fold_status),
      n_failed_folds = sum(x$fold_status$status == "fail"),
      task = x$task
    ),
    class = "gp3ml_resample_performance_summary"
  )
}

#' Validate a grouped-fold evaluation result
#'
#' @param x A `gp3ml_resample_evaluation`.
#'
#' @return A `gp3ml_resample_evaluation_validation` object.
#' @export
validate_gazepoint_resample_evaluation <- function(x) {
  if (!inherits(x, "gp3ml_resample_evaluation")) {
    .gp3ml_stop("`x` must be a `gp3ml_resample_evaluation` object.")
  }
  checks <- list(
    data.frame(
      check_id = "fold_status_complete",
      status = if (nrow(x$fold_status) == x$folds_metadata$n_folds_total) "pass" else "fail",
      message = sprintf(
        "Recorded %d of %d expected fold statuses.",
        nrow(x$fold_status),
        x$folds_metadata$n_folds_total
      ),
      stringsAsFactors = FALSE
    ),
    data.frame(
      check_id = "assessment_only_predictions",
      status = if (!nrow(x$predictions) || all(x$predictions$stage == "assessment")) "pass" else "fail",
      message = "Predictions are restricted to assessment partitions.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      check_id = "prediction_coverage",
      status = if (any(x$fold_status$n_missing_predictions > 0L)) "review" else "pass",
      message = sprintf(
        "%d assessment predictions are missing across folds.",
        sum(x$fold_status$n_missing_predictions)
      ),
      stringsAsFactors = FALSE
    ),
    data.frame(
      check_id = "fold_failures",
      status = if (any(x$fold_status$status == "fail")) "review" else "pass",
      message = sprintf(
        "%d folds failed and remain explicitly retained.",
        sum(x$fold_status$status == "fail")
      ),
      stringsAsFactors = FALSE
    ),
    data.frame(
      check_id = "generalization_target_preserved",
      status = if (identical(x$generalization_target, x$task$generalization_target)) "pass" else "fail",
      message = sprintf("Generalization target: %s.", x$generalization_target),
      stringsAsFactors = FALSE
    )
  )
  checks <- .gp3ml_bind_rows(checks)
  structure(
    list(
      status = .gp3ml_worst_status(checks$status),
      checks = checks,
      issues = checks[checks$status != "pass", , drop = FALSE]
    ),
    class = "gp3ml_resample_evaluation_validation"
  )
}

#' Write grouped-fold evaluation tables
#'
#' @param x A `gp3ml_resample_evaluation`.
#' @param directory Output directory.
#' @param prefix Filename prefix.
#' @param overwrite Whether existing files may be replaced.
#'
#' @return Named output paths, invisibly.
#' @export
write_gazepoint_resample_evaluation <- function(
    x,
    directory,
    prefix = "gazepoint_resample_evaluation",
    overwrite = FALSE) {
  if (!inherits(x, "gp3ml_resample_evaluation")) {
    .gp3ml_stop("`x` must be a `gp3ml_resample_evaluation` object.")
  }
  invisible(.gp3ml_write_tables(
    list(
      fold_status = x$fold_status,
      predictions = x$predictions,
      metrics = x$metrics,
      excluded = x$excluded,
      validation = x$validation$checks
    ),
    directory,
    prefix,
    overwrite
  ))
}

#' @rdname evaluate_gazepoint_group_folds
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_resample_evaluation
#' @export
print.gp3ml_resample_evaluation <- function(x, ...) {
  cat("<gp3ml_resample_evaluation>\n")
  cat("  Target: ", x$generalization_target, "\n", sep = "")
  cat("  Engine: ", x$engine, "\n", sep = "")
  cat("  Folds: ", nrow(x$fold_status), "\n", sep = "")
  cat("  Passed/review/failed: ",
      sum(x$fold_status$status == "pass"), "/",
      sum(x$fold_status$status == "review"), "/",
      sum(x$fold_status$status == "fail"), "\n", sep = "")
  cat("  Predictions: ", nrow(x$predictions), "\n", sep = "")
  invisible(x)
}

#' @rdname summarize_gazepoint_resample_performance
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_resample_performance_summary
#' @export
print.gp3ml_resample_performance_summary <- function(x, ...) {
  cat("<gp3ml_resample_performance_summary>\n")
  cat("  Aggregation: ", x$aggregation, "\n", sep = "")
  cat("  Generalization target: ", x$generalization_target, "\n", sep = "")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' @rdname validate_gazepoint_resample_evaluation
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_resample_evaluation_validation
#' @export
print.gp3ml_resample_evaluation_validation <- function(x, ...) {
  cat("<gp3ml_resample_evaluation_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}
