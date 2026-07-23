.gp3ml_cluster_bootstrap_indices <- function(id) {
  id <- as.character(id)
  if (anyNA(id) || any(!nzchar(id))) .gp3ml_stop("Cluster identifiers may not be missing or empty.")
  clusters <- unique(id)
  sampled <- sample(clusters, length(clusters), replace = TRUE)
  unlist(lapply(sampled, function(value) which(id == value)), use.names = FALSE)
}

.gp3ml_two_way_bootstrap_indices <- function(participant_id, stimulus_id, max_attempts = 100L) {
  participant_id <- as.character(participant_id)
  stimulus_id <- as.character(stimulus_id)
  if (length(participant_id) != length(stimulus_id)) .gp3ml_stop("Participant and stimulus identifiers must have equal length.")
  if (anyNA(participant_id) || anyNA(stimulus_id)) .gp3ml_stop("Two-way cluster identifiers may not be missing.")
  participants <- unique(participant_id)
  stimuli <- unique(stimulus_id)
  for (attempt in seq_len(max_attempts)) {
    participant_draw <- sample(participants, length(participants), replace = TRUE)
    stimulus_draw <- sample(stimuli, length(stimuli), replace = TRUE)
    participant_count <- table(participant_draw)
    stimulus_count <- table(stimulus_draw)
    weight <- as.integer(participant_count[participant_id]) * as.integer(stimulus_count[stimulus_id])
    weight[is.na(weight)] <- 0L
    index <- rep.int(seq_along(weight), weight)
    if (length(index)) return(index)
  }
  integer()
}

.gp3ml_observation_bootstrap_indices <- function(truth, classification, stratify) {
  n <- length(truth)
  if (classification && isTRUE(stratify)) {
    groups <- split(seq_len(n), as.character(truth))
    if (length(groups) != 2L) return(integer())
    return(unlist(lapply(groups, function(index) sample(index, length(index), replace = TRUE)), use.names = FALSE))
  }
  sample.int(n, n, replace = TRUE)
}

#' Generalization-target-aligned bootstrap uncertainty
#'
#' Resamples observations or declared clusters while preserving every row that
#' belongs to a sampled cluster. Repeated cluster draws duplicate all associated
#' rows. The returned object records the resampling unit and must not be
#' described as uncertainty for another unit.
#'
#' @param task Governed task.
#' @param truth Observed outcomes.
#' @param prediction Predicted classes or numeric outcomes.
#' @param probability Positive-class probabilities.
#' @param participant_id Participant identifiers for participant-based methods.
#' @param stimulus_id Stimulus identifiers for stimulus-based methods.
#' @param unit Resampling unit.
#' @param bootstrap Number of replicates.
#' @param conf_level Percentile interval level.
#' @param seed Deterministic seed.
#' @param threshold Classification threshold.
#' @param stratify_observations Whether the observation-level classification
#'   bootstrap preserves class counts.
#'
#' @return A `gp3ml_target_uncertainty` object.
#' @examples
#' data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 404L)
#' task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
#' probability <- seq(0.15, 0.85, length.out = nrow(data))
#' prediction <- factor(
#'   ifelse(probability >= 0.5, "review", "pass"),
#'   levels = levels(data$quality_status)
#' )
#' uncertainty <- bootstrap_gazepoint_metrics_by_unit(
#'   task,
#'   truth = data$quality_status,
#'   prediction = prediction,
#'   probability = probability,
#'   participant_id = data$participant_id,
#'   unit = "participant",
#'   bootstrap = 20L,
#'   seed = 404L
#' )
#' uncertainty
#' @export
bootstrap_gazepoint_metrics_by_unit <- function(
    task,
    truth,
    prediction = NULL,
    probability = NULL,
    participant_id = NULL,
    stimulus_id = NULL,
    unit = c("observation", "participant", "stimulus", "participant_and_stimulus"),
    bootstrap = 1000L,
    conf_level = 0.95,
    seed = 1L,
    threshold = 0.5,
    stratify_observations = TRUE) {
  assert_gp3ml_use_case(task)
  unit <- match.arg(unit)
  bootstrap <- as.integer(bootstrap)
  if (bootstrap < 1L) .gp3ml_stop("`bootstrap` must be positive.")
  n <- length(truth)
  if (n < 2L) .gp3ml_stop("At least two observations are required.")
  if (task$task_type == "classification" && length(probability) != n) {
    .gp3ml_stop("`probability` must match `truth`.")
  }
  if (task$task_type == "regression" && length(prediction) != n) {
    .gp3ml_stop("`prediction` must match `truth`.")
  }
  if (unit %in% c("participant", "participant_and_stimulus") && length(participant_id) != n) {
    .gp3ml_stop("`participant_id` must match `truth` for this resampling unit.")
  }
  if (unit %in% c("stimulus", "participant_and_stimulus") && length(stimulus_id) != n) {
    .gp3ml_stop("`stimulus_id` must match `truth` for this resampling unit.")
  }
  point <- gazepoint_performance_metrics(task, truth, prediction, probability, threshold)
  restore <- .gp3ml_set_seed(seed)
  on.exit(restore(), add = TRUE)
  draws <- vector("list", bootstrap)
  failures <- vector("list", bootstrap)
  replicate_sizes <- integer(bootstrap)
  for (i in seq_len(bootstrap)) {
    index <- switch(
      unit,
      observation = .gp3ml_observation_bootstrap_indices(
        truth,
        task$task_type == "classification",
        stratify_observations
      ),
      participant = .gp3ml_cluster_bootstrap_indices(participant_id),
      stimulus = .gp3ml_cluster_bootstrap_indices(stimulus_id),
      participant_and_stimulus = .gp3ml_two_way_bootstrap_indices(participant_id, stimulus_id)
    )
    replicate_sizes[[i]] <- length(index)
    if (!length(index)) {
      failures[[i]] <- data.frame(replicate = i, error = "No rows were selected.", stringsAsFactors = FALSE)
      next
    }
    captured <- .gp3ml_capture_conditions(
      gazepoint_performance_metrics(
        task,
        truth = truth[index],
        prediction = if (is.null(prediction)) NULL else prediction[index],
        probability = if (is.null(probability)) NULL else probability[index],
        threshold = threshold
      )
    )
    if (!is.na(captured$error)) {
      failures[[i]] <- data.frame(replicate = i, error = captured$error, stringsAsFactors = FALSE)
    } else {
      draw <- captured$value
      draw$replicate <- i
      draw$resample_n <- length(index)
      draws[[i]] <- draw
    }
  }
  draws <- .gp3ml_bind_rows(draws)
  failures <- .gp3ml_bind_rows(failures)
  if (!nrow(draws)) .gp3ml_stop("Every bootstrap replicate failed.")
  metric_columns <- names(draws)[vapply(draws, is.numeric, logical(1))]
  metric_columns <- setdiff(metric_columns, c("n", "threshold", "replicate", "resample_n"))
  alpha <- (1 - conf_level) / 2
  intervals <- data.frame(
    metric = metric_columns,
    estimate = vapply(metric_columns, function(name) as.numeric(point[[name]][[1L]]), numeric(1)),
    lower = vapply(metric_columns, function(name) as.numeric(stats::quantile(draws[[name]], alpha, na.rm = TRUE)), numeric(1)),
    upper = vapply(metric_columns, function(name) as.numeric(stats::quantile(draws[[name]], 1 - alpha, na.rm = TRUE)), numeric(1)),
    successful_replicates = vapply(metric_columns, function(name) sum(is.finite(draws[[name]])), integer(1)),
    stringsAsFactors = FALSE
  )
  structure(
    list(
      point = point,
      intervals = intervals,
      draws = draws,
      failures = failures,
      bootstrap = bootstrap,
      successful_replicates = length(unique(draws$replicate)),
      failed_replicates = nrow(failures),
      conf_level = conf_level,
      seed = seed,
      unit = unit,
      generalization_target = task$generalization_target,
      task = task,
      replicate_sizes = replicate_sizes,
      limitations = switch(
        unit,
        observation = "Observation-level intervals do not represent participant- or stimulus-cluster uncertainty.",
        participant = "Participant-cluster intervals preserve participant rows but do not independently resample stimuli.",
        stimulus = "Stimulus-cluster intervals preserve stimulus rows but do not independently resample participants.",
        participant_and_stimulus = "Two-way product-weight bootstrap reflects simultaneous participant and stimulus resampling and may produce variable replicate sizes."
      ),
      call = match.call()
    ),
    class = "gp3ml_target_uncertainty"
  )
}

#' Summarize uncertainty across folds or repeats
#'
#' @param evaluation A `gp3ml_resample_evaluation` or
#'   `gp3ml_nested_evaluation`.
#' @param unit Distribution unit: individual folds or repeat means.
#' @param conf_level Quantile interval level.
#'
#' @return A `gp3ml_resample_uncertainty` object.
#' @export
summarize_gazepoint_resample_uncertainty <- function(
    evaluation,
    unit = c("fold", "repeat"),
    conf_level = 0.95) {
  if (!inherits(evaluation, c("gp3ml_resample_evaluation", "gp3ml_nested_evaluation"))) {
    .gp3ml_stop("`evaluation` must be a grouped or nested evaluation object.")
  }
  unit <- match.arg(unit)
  metrics <- evaluation$metrics
  if (!nrow(metrics)) .gp3ml_stop("The evaluation contains no metric values.")
  if (unit == "repeat") {
    repeat_means <- stats::aggregate(
      value ~ repeat + metric,
      data = metrics,
      FUN = function(x) mean(x, na.rm = TRUE)
    )
    distribution <- repeat_means
  } else {
    distribution <- metrics[c("repeat", "fold", "fold_id", "metric", "value")]
  }
  summary <- .gp3ml_bind_rows(lapply(unique(distribution$metric), function(metric) {
    values <- distribution$value[distribution$metric == metric]
    interval <- .gp3ml_quantile_interval(values, conf_level)
    data.frame(
      metric = metric,
      distribution_unit = unit,
      n_units = sum(is.finite(values)),
      mean = mean(values, na.rm = TRUE),
      median = stats::median(values, na.rm = TRUE),
      sd = stats::sd(values, na.rm = TRUE),
      lower = interval[[1L]],
      upper = interval[[2L]],
      stringsAsFactors = FALSE
    )
  }))
  structure(
    list(
      summary = summary,
      distribution = distribution,
      unit = unit,
      conf_level = conf_level,
      generalization_target = evaluation$generalization_target,
      limitations = paste(
        "Intervals summarize the empirical", unit,
        "distribution and are not a substitute for an undeclared cluster bootstrap."
      )
    ),
    class = "gp3ml_resample_uncertainty"
  )
}

#' Validate target-aligned uncertainty metadata
#'
#' @param x A `gp3ml_target_uncertainty` or `gp3ml_resample_uncertainty`.
#' @return A `gp3ml_uncertainty_validation`.
#' @export
validate_gazepoint_target_uncertainty <- function(x) {
  if (!inherits(x, c("gp3ml_target_uncertainty", "gp3ml_resample_uncertainty"))) {
    .gp3ml_stop("`x` must be a gp3ml uncertainty object.")
  }
  unit <- x$unit
  checks <- data.frame(
    check_id = c("unit_recorded", "target_recorded", "limitations_recorded", "failed_replicates_recorded"),
    status = c(
      if (!is.null(unit) && nzchar(unit)) "pass" else "fail",
      if (!is.null(x$generalization_target) && nzchar(x$generalization_target)) "pass" else "fail",
      if (!is.null(x$limitations) && nzchar(x$limitations)) "pass" else "fail",
      if (inherits(x, "gp3ml_target_uncertainty") && !is.null(x$failed_replicates)) "pass" else if (inherits(x, "gp3ml_resample_uncertainty")) "pass" else "fail"
    ),
    message = c(
      paste("Resampling unit:", unit),
      paste("Generalization target:", x$generalization_target),
      x$limitations,
      if (inherits(x, "gp3ml_target_uncertainty")) paste("Failed replicates:", x$failed_replicates) else "Not a bootstrap object."
    ),
    stringsAsFactors = FALSE
  )
  structure(
    list(status = .gp3ml_worst_status(checks$status), checks = checks, issues = checks[checks$status != "pass", , drop = FALSE]),
    class = "gp3ml_uncertainty_validation"
  )
}

#' Write target-aligned uncertainty tables
#'
#' @param x A gp3ml uncertainty object.
#' @param directory Output directory.
#' @param prefix Filename prefix.
#' @param overwrite Whether existing files may be replaced.
#' @return Named paths, invisibly.
#' @export
write_gazepoint_target_uncertainty <- function(
    x,
    directory,
    prefix = "gazepoint_target_uncertainty",
    overwrite = FALSE) {
  validation <- validate_gazepoint_target_uncertainty(x)
  tables <- if (inherits(x, "gp3ml_target_uncertainty")) {
    list(point = x$point, intervals = x$intervals, draws = x$draws, failures = x$failures, validation = validation$checks)
  } else {
    list(summary = x$summary, distribution = x$distribution, validation = validation$checks)
  }
  invisible(.gp3ml_write_tables(tables, directory, prefix, overwrite))
}

#' @rdname bootstrap_gazepoint_metrics_by_unit
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_target_uncertainty
#' @export
print.gp3ml_target_uncertainty <- function(x, ...) {
  cat("<gp3ml_target_uncertainty>\n")
  cat("  Unit: ", x$unit, "\n", sep = "")
  cat("  Target: ", x$generalization_target, "\n", sep = "")
  cat("  Successful/failed replicates: ", x$successful_replicates, "/", x$failed_replicates, "\n", sep = "")
  print(x$intervals, row.names = FALSE)
  invisible(x)
}

#' @rdname summarize_gazepoint_resample_uncertainty
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_resample_uncertainty
#' @export
print.gp3ml_resample_uncertainty <- function(x, ...) {
  cat("<gp3ml_resample_uncertainty> unit=", x$unit, "\n", sep = "")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' @rdname validate_gazepoint_target_uncertainty
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_uncertainty_validation
#' @export
print.gp3ml_uncertainty_validation <- function(x, ...) {
  cat("<gp3ml_uncertainty_validation> status=", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}
