.gp3ml_expand_grid_list <- function(grid) {
  if (is.null(grid) || !length(grid)) return(list(list()))
  if (!is.list(grid) || is.null(names(grid)) || any(!nzchar(names(grid)))) {
    .gp3ml_stop("A tuning grid must be a named list of candidate values.")
  }
  lengths <- vapply(grid, length, integer(1))
  if (any(lengths < 1L)) .gp3ml_stop("Every tuning parameter needs at least one value.")
  indices <- do.call(
    expand.grid,
    c(lapply(lengths, seq_len), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  )
  lapply(seq_len(nrow(indices)), function(i) {
    stats::setNames(
      lapply(seq_along(grid), function(j) grid[[j]][[indices[i, j]]]),
      names(grid)
    )
  })
}

.gp3ml_candidate_label <- function(engine, engine_args, preprocessor_args, threshold) {
  collapse <- function(x) {
    if (!length(x)) return("default")
    paste(vapply(names(x), function(name) {
      value <- paste(as.character(x[[name]]), collapse = "/")
      paste0(name, "=", value)
    }, character(1)), collapse = ",")
  }
  paste0(
    engine,
    " [engine:", collapse(engine_args),
    "; prep:", collapse(preprocessor_args),
    "; threshold=", format(threshold, trim = TRUE), "]"
  )
}

#' Create an explicit governed tuning grid
#'
#' Candidate values are fully materialized before evaluation. No hidden metric,
#' default ranking rule, or automatic winner is created.
#'
#' @param engine One or more governed engine names.
#' @param engine_grid Named list of engine-argument candidate values.
#' @param preprocessor_grid Named list of preprocessing-argument candidate values.
#' @param thresholds One or more explicit classification thresholds.
#' @param complexity Optional complexity labels or numeric scores.
#' @param interpretability Optional interpretability labels or numeric scores.
#' @param labels Optional candidate labels.
#'
#' @return A `gp3ml_tuning_grid` with one row per explicit candidate.
#' @examples
#' grid <- create_gazepoint_tuning_grid(
#'   engine = "glm",
#'   preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
#'   thresholds = c(0.4, 0.5),
#'   complexity = "low",
#'   interpretability = "high"
#' )
#' grid
#' @export
create_gazepoint_tuning_grid <- function(
    engine,
    engine_grid = list(),
    preprocessor_grid = list(),
    thresholds = 0.5,
    complexity = NA,
    interpretability = NA,
    labels = NULL) {
  engine <- unique(as.character(engine))
  if (!length(engine) || anyNA(engine) || any(!nzchar(engine))) {
    .gp3ml_stop("`engine` must contain one or more non-empty engine names.")
  }
  thresholds <- as.numeric(thresholds)
  if (!length(thresholds) || any(!is.finite(thresholds)) || any(thresholds <= 0 | thresholds >= 1)) {
    .gp3ml_stop("`thresholds` must contain finite values strictly between zero and one.")
  }
  engine_combinations <- .gp3ml_expand_grid_list(engine_grid)
  preprocessor_combinations <- .gp3ml_expand_grid_list(preprocessor_grid)
  index <- expand.grid(
    engine = engine,
    engine_index = seq_along(engine_combinations),
    preprocessor_index = seq_along(preprocessor_combinations),
    threshold = thresholds,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  n <- nrow(index)
  recycle_metadata <- function(value, name) {
    if (length(value) == 1L) return(rep(value, n))
    if (length(value) != n) .gp3ml_stop("`%s` must have length one or the candidate count.", name)
    value
  }
  candidate_id <- sprintf("candidate_%03d", seq_len(n))
  engine_args <- lapply(index$engine_index, function(i) engine_combinations[[i]])
  preprocessor_args <- lapply(index$preprocessor_index, function(i) preprocessor_combinations[[i]])
  generated_labels <- vapply(seq_len(n), function(i) {
    .gp3ml_candidate_label(
      index$engine[[i]],
      engine_args[[i]],
      preprocessor_args[[i]],
      index$threshold[[i]]
    )
  }, character(1))
  if (!is.null(labels)) generated_labels <- recycle_metadata(labels, "labels")
  out <- data.frame(
    candidate_id = candidate_id,
    label = as.character(generated_labels),
    engine = index$engine,
    threshold = index$threshold,
    complexity = recycle_metadata(complexity, "complexity"),
    interpretability = recycle_metadata(interpretability, "interpretability"),
    stringsAsFactors = FALSE
  )
  out$engine_args <- .gp3ml_list_column(engine_args)
  out$preprocessor_args <- .gp3ml_list_column(preprocessor_args)
  structure(
    list(candidates = out, created = Sys.time(), call = match.call()),
    class = "gp3ml_tuning_grid"
  )
}

#' Evaluate every governed candidate on the same grouped folds
#'
#' @param folds A `gazepoint_group_folds` object.
#' @param task A governed task.
#' @param tuning_grid A `gp3ml_tuning_grid`.
#' @param predictors Optional declared predictors.
#' @param metrics Optional metric names retained in the comparison table.
#' @param seed Base deterministic seed.
#' @param continue_on_error Whether failed candidates remain in the result while
#'   later candidates continue.
#' @param keep_evaluations Whether complete candidate evaluations are retained.
#'
#' @return A `gp3ml_model_tuning` object retaining all candidates and failures.
#' @examples
#' data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 202L)
#' predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
#' manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
#' folds <- create_gazepoint_group_folds(
#'   data, "quality_status", predictors, manifest,
#'   "new_participants", "participant_id", "trial_id", "stimulus_id",
#'   v = 3L, repeats = 1L, seed = 202L
#' )
#' task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
#' grid <- create_gazepoint_tuning_grid(
#'   "glm",
#'   preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
#'   thresholds = 0.5
#' )
#' tuned <- tune_gazepoint_model(folds, task, grid, predictors, seed = 202L)
#' tuned
#' @export
tune_gazepoint_model <- function(
    folds,
    task,
    tuning_grid,
    predictors = NULL,
    metrics = NULL,
    seed = 1L,
    continue_on_error = TRUE,
    keep_evaluations = TRUE) {
  if (!inherits(tuning_grid, "gp3ml_tuning_grid")) {
    .gp3ml_stop("`tuning_grid` must be a `gp3ml_tuning_grid` object.")
  }
  candidates <- tuning_grid$candidates
  results <- vector("list", nrow(candidates))
  names(results) <- candidates$candidate_id
  for (i in seq_len(nrow(candidates))) {
    candidate <- candidates[i, , drop = FALSE]
    candidate_seed <- .gp3ml_seed_from(seed, candidate$candidate_id)
    captured <- .gp3ml_capture_conditions(
      evaluate_gazepoint_group_folds(
        folds = folds,
        task = task,
        predictors = predictors,
        engine = candidate$engine[[1L]],
        preprocessor_args = candidate$preprocessor_args[[1L]],
        engine_args = candidate$engine_args[[1L]],
        threshold = candidate$threshold[[1L]],
        seed = candidate_seed,
        assess_calibration = task$task_type == "classification",
        calibration_bootstrap = 0L,
        keep_models = FALSE,
        continue_on_error = TRUE
      )
    )
    failed <- !is.na(captured$error)
    evaluation <- if (failed) NULL else captured$value
    fold_status <- if (failed) data.frame() else evaluation$fold_status
    success_prop <- if (failed || !nrow(fold_status)) {
      0
    } else {
      mean(fold_status$status != "fail")
    }
    all_folds_failed <- !failed && nrow(fold_status) > 0L &&
      all(fold_status$status == "fail")
    candidate_failed <- failed || all_folds_failed
    candidate_error <- if (failed) {
      captured$error
    } else if (all_folds_failed) {
      errors <- unique(fold_status$error[!is.na(fold_status$error) & nzchar(fold_status$error)])
      if (length(errors)) paste(errors, collapse = " | ") else "Every grouped fold failed."
    } else {
      NA_character_
    }
    fold_warnings <- if (!failed && nrow(fold_status)) {
      unique(fold_status$warnings[!is.na(fold_status$warnings) & nzchar(fold_status$warnings)])
    } else {
      character()
    }
    candidate_warnings <- unique(c(captured$warnings, fold_warnings))
    candidate_metrics <- if (candidate_failed) data.frame() else evaluation$metrics
    if (!is.null(metrics) && nrow(candidate_metrics)) {
      candidate_metrics <- candidate_metrics[candidate_metrics$metric %in% metrics, , drop = FALSE]
    }
    results[[i]] <- list(
      candidate_id = candidate$candidate_id[[1L]],
      candidate = candidate,
      status = if (candidate_failed) "fail" else evaluation$validation$status,
      error = candidate_error,
      warnings = candidate_warnings,
      metrics = candidate_metrics,
      fold_status = fold_status,
      success_prop = success_prop,
      evaluation = if (!failed && isTRUE(keep_evaluations)) evaluation else NULL,
      seed = candidate_seed
    )
    if (candidate_failed && !isTRUE(continue_on_error)) {
      .gp3ml_stop("Candidate `%s` failed: %s", candidate$candidate_id, candidate_error)
    }
  }
  comparison <- .gp3ml_model_comparison_table(results)
  object <- structure(
    list(
      grid = tuning_grid,
      results = results,
      comparison = comparison,
      task = task,
      predictors = predictors %||% folds$metadata$predictors,
      folds_metadata = folds$metadata,
      metrics_requested = metrics,
      seed = seed,
      keep_evaluations = keep_evaluations,
      selection = NULL,
      call = match.call()
    ),
    class = "gp3ml_model_tuning"
  )
  object$validation <- validate_gazepoint_model_tuning(object)
  object
}

.gp3ml_model_comparison_table <- function(results) {
  .gp3ml_bind_rows(lapply(results, function(result) {
    candidate <- result$candidate
    base <- data.frame(
      candidate_id = result$candidate_id,
      label = candidate$label[[1L]],
      engine = candidate$engine[[1L]],
      threshold = candidate$threshold[[1L]],
      complexity = as.character(candidate$complexity[[1L]]),
      interpretability = as.character(candidate$interpretability[[1L]]),
      candidate_status = result$status,
      success_prop = result$success_prop,
      failed_folds = if (nrow(result$fold_status)) sum(result$fold_status$status == "fail") else NA_integer_,
      error = result$error,
      stringsAsFactors = FALSE
    )
    if (!nrow(result$metrics)) {
      base$metric <- NA_character_
      base$mean <- NA_real_
      base$sd <- NA_real_
      base$n_folds <- 0L
      base$direction <- NA_character_
      return(base)
    }
    metric_names <- unique(result$metrics$metric)
    .gp3ml_bind_rows(lapply(metric_names, function(metric) {
      values <- result$metrics$value[result$metrics$metric == metric]
      row <- base
      row$metric <- metric
      row$mean <- mean(values, na.rm = TRUE)
      row$sd <- stats::sd(values, na.rm = TRUE)
      row$n_folds <- sum(is.finite(values))
      row$direction <- .gp3ml_roadmap_metric_direction(metric)
      row
    }))
  }))
}

#' Compare governed model candidates without selecting a winner
#'
#' @param x A `gp3ml_model_tuning` object.
#' @param metrics Optional metric names.
#'
#' @return A data frame retaining candidate status, failures, complexity,
#'   interpretability, and fold-distribution summaries.
#' @export
compare_gazepoint_models <- function(x, metrics = NULL) {
  if (!inherits(x, "gp3ml_model_tuning")) {
    .gp3ml_stop("`x` must be a `gp3ml_model_tuning` object.")
  }
  out <- x$comparison
  if (!is.null(metrics)) out <- out[is.na(out$metric) | out$metric %in% metrics, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Select a governed candidate using an explicit metric and direction
#'
#' This function records a reviewable decision. It does not refit a model and
#' refuses accuracy as the sole primary metric.
#'
#' @param x A `gp3ml_model_tuning` object.
#' @param metric Explicit primary metric.
#' @param direction Explicit optimization direction.
#' @param minimum_success_prop Minimum successful-fold proportion.
#' @param tie_breakers Optional ordered secondary metric names.
#' @param rationale Required human-readable selection rationale.
#'
#' @return A `gp3ml_model_selection` object.
#' @export
select_gazepoint_model <- function(
    x,
    metric,
    direction,
    minimum_success_prop = 0.8,
    tie_breakers = NULL,
    rationale) {
  if (!inherits(x, "gp3ml_model_tuning")) {
    .gp3ml_stop("`x` must be a `gp3ml_model_tuning` object.")
  }
  if (missing(metric) || length(metric) != 1L || !nzchar(metric)) {
    .gp3ml_stop("An explicit primary `metric` is required.")
  }
  if (missing(direction)) {
    .gp3ml_stop("An explicit optimization `direction` is required.")
  }
  if (missing(rationale) || length(rationale) != 1L || !nzchar(trimws(rationale))) {
    .gp3ml_stop("A non-empty human review `rationale` is required.")
  }
  direction <- .gp3ml_validate_direction(metric, direction)
  if (!is.numeric(minimum_success_prop) || length(minimum_success_prop) != 1L ||
      minimum_success_prop < 0 || minimum_success_prop > 1) {
    .gp3ml_stop("`minimum_success_prop` must be between zero and one.")
  }
  comparison <- x$comparison
  eligible <- comparison[
    comparison$metric == metric &
      comparison$candidate_status != "fail" &
      comparison$success_prop >= minimum_success_prop &
      is.finite(comparison$mean),
    , drop = FALSE
  ]
  if (!nrow(eligible)) .gp3ml_stop("No eligible candidate has the requested metric.")
  order_primary <- if (direction == "maximize") order(-eligible$mean) else order(eligible$mean)
  eligible <- eligible[order_primary, , drop = FALSE]
  best_value <- eligible$mean[[1L]]
  tied_ids <- eligible$candidate_id[eligible$mean == best_value]
  tie_breaker_record <- data.frame()
  if (length(tied_ids) > 1L && length(tie_breakers)) {
    for (secondary in tie_breakers) {
      if (identical(secondary, "accuracy")) next
      secondary_rows <- comparison[
        comparison$candidate_id %in% tied_ids & comparison$metric == secondary,
        , drop = FALSE
      ]
      secondary_rows <- secondary_rows[is.finite(secondary_rows$mean), , drop = FALSE]
      if (!nrow(secondary_rows)) next
      secondary_direction <- .gp3ml_roadmap_metric_direction(secondary)
      secondary_rows <- secondary_rows[
        if (secondary_direction == "maximize") order(-secondary_rows$mean) else order(secondary_rows$mean),
        , drop = FALSE
      ]
      secondary_best <- secondary_rows$mean[[1L]]
      tied_ids <- secondary_rows$candidate_id[secondary_rows$mean == secondary_best]
      tie_breaker_record <- rbind(
        tie_breaker_record,
        data.frame(
          metric = secondary,
          direction = secondary_direction,
          best_value = secondary_best,
          remaining_candidates = paste(tied_ids, collapse = ","),
          stringsAsFactors = FALSE
        )
      )
      if (length(tied_ids) == 1L) break
    }
  }
  if (length(tied_ids) > 1L) {
    candidate_rows <- x$grid$candidates[x$grid$candidates$candidate_id %in% tied_ids, , drop = FALSE]
    complexity_text <- as.character(candidate_rows$complexity)
    complexity_numeric <- suppressWarnings(as.numeric(complexity_text))
    if (all(is.finite(complexity_numeric))) {
      tied_ids <- candidate_rows$candidate_id[complexity_numeric == min(complexity_numeric)]
    }
  }
  if (length(tied_ids) != 1L) {
    .gp3ml_stop(
      "Selection remains tied among: %s. Supply defensible tie breakers or revise the candidate grid.",
      paste(tied_ids, collapse = ", ")
    )
  }
  selected_id <- tied_ids[[1L]]
  selected_candidate <- x$grid$candidates[x$grid$candidates$candidate_id == selected_id, , drop = FALSE]
  structure(
    list(
      candidate_id = selected_id,
      candidate = selected_candidate,
      primary_metric = metric,
      direction = direction,
      primary_value = comparison$mean[
        comparison$candidate_id == selected_id & comparison$metric == metric
      ][[1L]],
      minimum_success_prop = minimum_success_prop,
      tie_breakers = tie_breaker_record,
      rationale = trimws(rationale),
      eligible_candidates = eligible$candidate_id,
      selection_time = Sys.time(),
      tuning_hash = .gp3ml_hash_object(x$comparison),
      refit_performed = FALSE,
      autonomous_selection = FALSE
    ),
    class = "gp3ml_model_selection"
  )
}

#' Validate governed tuning results
#'
#' @param x A `gp3ml_model_tuning` object.
#' @return A `gp3ml_model_tuning_validation`.
#' @export
validate_gazepoint_model_tuning <- function(x) {
  if (!inherits(x, "gp3ml_model_tuning")) {
    .gp3ml_stop("`x` must be a `gp3ml_model_tuning` object.")
  }
  expected <- nrow(x$grid$candidates)
  observed <- length(x$results)
  comparison_ids <- unique(x$comparison$candidate_id)
  checks <- data.frame(
    check_id = c(
      "all_candidates_retained",
      "candidate_ids_complete",
      "failures_retained",
      "no_implicit_selection",
      "generalization_target_preserved"
    ),
    status = c(
      if (expected == observed) "pass" else "fail",
      if (setequal(x$grid$candidates$candidate_id, comparison_ids)) "pass" else "fail",
      "pass",
      if (is.null(x$selection)) "pass" else "review",
      if (identical(x$task$generalization_target, x$folds_metadata$generalization_target)) "pass" else "fail"
    ),
    message = c(
      sprintf("Retained %d of %d candidates.", observed, expected),
      "Comparison table retains every candidate identifier.",
      sprintf("Explicitly retained %d failed candidates.", sum(vapply(x$results, function(z) z$status == "fail", logical(1)))),
      "Tuning does not automatically declare a winner.",
      sprintf("Generalization target: %s.", x$task$generalization_target)
    ),
    stringsAsFactors = FALSE
  )
  structure(
    list(status = .gp3ml_worst_status(checks$status), checks = checks, issues = checks[checks$status != "pass", , drop = FALSE]),
    class = "gp3ml_model_tuning_validation"
  )
}

#' @rdname create_gazepoint_tuning_grid
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_tuning_grid
#' @export
print.gp3ml_tuning_grid <- function(x, ...) {
  cat("<gp3ml_tuning_grid> candidates=", nrow(x$candidates), "\n", sep = "")
  print(x$candidates[c("candidate_id", "label", "engine", "threshold", "complexity", "interpretability")], row.names = FALSE)
  invisible(x)
}

#' @rdname tune_gazepoint_model
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_model_tuning
#' @export
print.gp3ml_model_tuning <- function(x, ...) {
  cat("<gp3ml_model_tuning>\n")
  cat("  Candidates: ", nrow(x$grid$candidates), "\n", sep = "")
  cat("  Failed candidates: ", sum(vapply(x$results, function(z) z$status == "fail", logical(1))), "\n", sep = "")
  cat("  Automatic winner: none\n")
  invisible(x)
}

#' @rdname select_gazepoint_model
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_model_selection
#' @export
print.gp3ml_model_selection <- function(x, ...) {
  cat("<gp3ml_model_selection>\n")
  cat("  Candidate: ", x$candidate_id, "\n", sep = "")
  cat("  Primary metric: ", x$primary_metric, " (", x$direction, ")\n", sep = "")
  cat("  Value: ", format(x$primary_value), "\n", sep = "")
  cat("  Human rationale: ", x$rationale, "\n", sep = "")
  cat("  Refit performed: no\n")
  invisible(x)
}

#' @rdname validate_gazepoint_model_tuning
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_model_tuning_validation
#' @export
print.gp3ml_model_tuning_validation <- function(x, ...) {
  cat("<gp3ml_model_tuning_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

.gp3ml_flatten_candidate_grid <- function(grid) {
  candidates <- grid$candidates
  candidates$engine_args <- vapply(candidates$engine_args, function(x) {
    if (!length(x)) return("")
    paste(vapply(names(x), function(name) paste0(name, "=", paste(as.character(x[[name]]), collapse = "/")), character(1)), collapse = ";")
  }, character(1))
  candidates$preprocessor_args <- vapply(candidates$preprocessor_args, function(x) {
    if (!length(x)) return("")
    paste(vapply(names(x), function(name) paste0(name, "=", paste(as.character(x[[name]]), collapse = "/")), character(1)), collapse = ";")
  }, character(1))
  candidates
}

#' Write governed tuning and selection tables
#'
#' @param x A `gp3ml_model_tuning` object.
#' @param directory Output directory.
#' @param prefix Filename prefix.
#' @param selection Optional `gp3ml_model_selection` to record.
#' @param overwrite Whether existing files may be replaced.
#'
#' @return Named output paths, invisibly.
#' @export
write_gazepoint_model_tuning <- function(
    x,
    directory,
    prefix = "gazepoint_model_tuning",
    selection = NULL,
    overwrite = FALSE) {
  if (!inherits(x, "gp3ml_model_tuning")) {
    .gp3ml_stop("`x` must be a `gp3ml_model_tuning` object.")
  }
  if (!is.null(selection) && !inherits(selection, "gp3ml_model_selection")) {
    .gp3ml_stop("`selection` must be a `gp3ml_model_selection` object.")
  }
  candidate_status <- .gp3ml_bind_rows(lapply(x$results, function(result) {
    data.frame(
      candidate_id = result$candidate_id,
      status = result$status,
      success_prop = result$success_prop,
      warning_count = length(result$warnings),
      warnings = paste(result$warnings, collapse = " | "),
      error = result$error,
      stringsAsFactors = FALSE
    )
  }))
  selection_table <- if (is.null(selection)) {
    data.frame()
  } else {
    data.frame(
      candidate_id = selection$candidate_id,
      primary_metric = selection$primary_metric,
      direction = selection$direction,
      primary_value = selection$primary_value,
      minimum_success_prop = selection$minimum_success_prop,
      rationale = selection$rationale,
      autonomous_selection = selection$autonomous_selection,
      refit_performed = selection$refit_performed,
      stringsAsFactors = FALSE
    )
  }
  invisible(.gp3ml_write_tables(
    list(
      candidates = .gp3ml_flatten_candidate_grid(x$grid),
      candidate_status = candidate_status,
      comparison = x$comparison,
      selection = selection_table,
      validation = x$validation$checks
    ),
    directory,
    prefix,
    overwrite
  ))
}
