.gp3ml_binary_values <- function(truth, positive = NULL) {
  values <- as.character(truth)
  levels_found <- sort(unique(values[!is.na(values)]))
  if (length(levels_found) != 2L) .gp3ml_stop("Binary metrics require exactly two truth levels.")
  positive <- positive %||% levels_found[[2L]]
  if (!positive %in% levels_found) .gp3ml_stop("Unknown positive level.")
  list(y = as.integer(values == positive), positive = positive, negative = setdiff(levels_found, positive)[[1L]])
}

.gp3ml_auc <- function(y, probability) {
  keep <- !is.na(y) & !is.na(probability)
  y <- y[keep]; probability <- probability[keep]
  n1 <- sum(y == 1L); n0 <- sum(y == 0L)
  if (!n1 || !n0) return(NA_real_)
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[y == 1L]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

.gp3ml_pr_auc <- function(y, probability) {
  keep <- !is.na(y) & !is.na(probability)
  y <- y[keep]; probability <- probability[keep]
  positives <- sum(y == 1L)
  if (!positives) return(NA_real_)
  ord <- order(probability, decreasing = TRUE)
  y <- y[ord]
  tp <- cumsum(y == 1L)
  fp <- cumsum(y == 0L)
  recall <- tp / positives
  precision <- tp / pmax(tp + fp, 1)
  sum(diff(c(0, recall)) * precision)
}

#' Binary classification metrics
#'
#' @param truth Observed binary outcome values.
#' @param probability Predicted positive-class probabilities.
#' @param predicted Optional predicted classes.
#' @param positive Label representing the positive class.
#' @param threshold Probability threshold used for class predictions.
#'
#' @examples
#' truth <- factor(
#'   rep(c("pass", "review"), 6),
#'   levels = c("pass", "review")
#' )
#' probability <- c(
#'   0.20, 0.70, 0.60, 0.55, 0.30, 0.80,
#'   0.65, 0.45, 0.40, 0.75, 0.50, 0.60
#' )
#' predicted <- factor(
#'   ifelse(probability >= 0.5, "review", "pass"),
#'   levels = levels(truth)
#' )
#' gazepoint_classification_metrics(
#'   truth = truth,
#'   probability = probability,
#'   predicted = predicted,
#'   positive = "review"
#' )
#' @return A one-row data frame containing the sample size, threshold, class-performance measures, discrimination metrics, Brier score, and log loss.
#' @export
gazepoint_classification_metrics <- function(truth, probability, predicted = NULL, positive = NULL, threshold = 0.5) {
  binary <- .gp3ml_binary_values(truth, positive)
  y <- binary$y
  p <- .gp3ml_clip_probability(probability)
  pred_y <- if (is.null(predicted)) as.integer(p >= threshold) else as.integer(as.character(predicted) == binary$positive)
  tp <- sum(pred_y == 1L & y == 1L, na.rm = TRUE)
  tn <- sum(pred_y == 0L & y == 0L, na.rm = TRUE)
  fp <- sum(pred_y == 1L & y == 0L, na.rm = TRUE)
  fn <- sum(pred_y == 0L & y == 1L, na.rm = TRUE)
  safe <- function(num, den) if (den == 0) NA_real_ else num / den
  sensitivity <- safe(tp, tp + fn)
  specificity <- safe(tn, tn + fp)
  precision <- safe(tp, tp + fp)
  f1 <- if (is.na(precision) || is.na(sensitivity) || precision + sensitivity == 0) NA_real_ else 2 * precision * sensitivity / (precision + sensitivity)
  mcc_den <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  data.frame(
    n = sum(!is.na(y) & !is.na(p)),
    threshold = threshold,
    accuracy = safe(tp + tn, tp + tn + fp + fn),
    balanced_accuracy = mean(c(sensitivity, specificity), na.rm = TRUE),
    sensitivity = sensitivity,
    specificity = specificity,
    precision = precision,
    recall = sensitivity,
    f1 = f1,
    mcc = if (mcc_den == 0) NA_real_ else (tp * tn - fp * fn) / mcc_den,
    roc_auc = .gp3ml_auc(y, p),
    pr_auc = .gp3ml_pr_auc(y, p),
    brier = mean((p - y)^2, na.rm = TRUE),
    log_loss = -mean(y * log(p) + (1 - y) * log(1 - p), na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

#' Regression metrics
#'
#' @param truth Observed numeric outcome values.
#' @param prediction Predicted numeric outcome values.
#'
#' @examples
#' truth <- c(1.0, 2.0, 3.0, 4.0, 5.0)
#' prediction <- c(1.1, 1.8, 3.2, 3.9, 4.8)
#' gazepoint_regression_metrics(truth, prediction)
#' @return A one-row data frame containing the sample size, RMSE, MAE, R-squared value, and prediction correlation.
#' @export
gazepoint_regression_metrics <- function(truth, prediction) {
  truth <- as.numeric(truth); prediction <- as.numeric(prediction)
  keep <- is.finite(truth) & is.finite(prediction)
  truth <- truth[keep]; prediction <- prediction[keep]
  residual <- truth - prediction
  sst <- sum((truth - mean(truth))^2)
  data.frame(
    n = length(truth),
    rmse = sqrt(mean(residual^2)),
    mae = mean(abs(residual)),
    r_squared = if (sst == 0) NA_real_ else 1 - sum(residual^2) / sst,
    correlation = if (length(truth) < 2L) NA_real_ else suppressWarnings(stats::cor(truth, prediction)),
    stringsAsFactors = FALSE
  )
}

#' Task-aware performance metrics
#'
#' @param task A governed `gp3ml_task` object.
#' @param truth Observed outcome values.
#' @param prediction Predicted classes or numeric values.
#' @param probability Predicted positive-class probabilities.
#' @param threshold Probability threshold for classification.
#'
#' @examples
#' example_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   condition = rep(c("A", "B"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' example_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = example_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' probability <- seq(
#'   0.20,
#'   0.80,
#'   length.out = nrow(example_data)
#' )
#' predicted <- factor(
#'   ifelse(probability >= 0.5, "review", "pass"),
#'   levels = levels(example_data$quality_status)
#' )
#' gazepoint_performance_metrics(
#'   task = task,
#'   truth = example_data$quality_status,
#'   prediction = predicted,
#'   probability = probability
#' )
#' @return A one-row data frame of classification or regression metrics selected according to the governed task type.
#' @export
gazepoint_performance_metrics <- function(task, truth, prediction = NULL, probability = NULL, threshold = 0.5) {
  assert_gp3ml_use_case(task)
  if (task$task_type == "classification") {
    gazepoint_classification_metrics(truth, probability, prediction, task$positive, threshold)
  } else {
    gazepoint_regression_metrics(truth, prediction)
  }
}

#' Bootstrap uncertainty intervals for performance metrics
#'
#'
#' @param task A governed `gp3ml_task` object.
#' @param truth Observed outcome values.
#' @param prediction Predicted classes or numeric values.
#' @param probability Predicted positive-class probabilities.
#' @param threshold Probability threshold for classification.
#' @param bootstrap Number of bootstrap replicates.
#' @param conf_level Confidence level for percentile intervals.
#' @param seed Deterministic random seed.
#'
#' @examples
#' example_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   condition = rep(c("A", "B"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' example_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = example_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' probability <- seq(
#'   0.20,
#'   0.80,
#'   length.out = nrow(example_data)
#' )
#' predicted <- factor(
#'   ifelse(probability >= 0.5, "review", "pass"),
#'   levels = levels(example_data$quality_status)
#' )
#' uncertainty <- bootstrap_gazepoint_metrics(
#'   task = task,
#'   truth = example_data$quality_status,
#'   prediction = predicted,
#'   probability = probability,
#'   bootstrap = 10L,
#'   seed = 101L
#' )
#' uncertainty
#' @return A `gp3ml_metric_uncertainty` object containing point estimates, percentile intervals, bootstrap draws, resampling settings, and the governed task.
#' @export
bootstrap_gazepoint_metrics <- function(
    task,
    truth,
    prediction = NULL,
    probability = NULL,
    threshold = 0.5,
    bootstrap = 1000L,
    conf_level = 0.95,
    seed = 1L) {
  assert_gp3ml_use_case(task)
  bootstrap <- as.integer(bootstrap)
  if (bootstrap < 1L) .gp3ml_stop("`bootstrap` must be positive.")
  n <- length(truth)
  if (n < 2L) .gp3ml_stop("At least two observations are required.")
  if (task$task_type == "classification" && length(probability) != n) .gp3ml_stop("`probability` must match `truth`.")
  if (task$task_type == "regression" && length(prediction) != n) .gp3ml_stop("`prediction` must match `truth`.")
  point <- gazepoint_performance_metrics(task, truth, prediction, probability, threshold)
  restore <- .gp3ml_set_seed(seed)
  on.exit(restore(), add = TRUE)
  draws <- vector("list", bootstrap)
  if (task$task_type == "classification") {
    classes <- split(seq_len(n), as.character(truth))
    if (length(classes) != 2L) .gp3ml_stop("Binary bootstrap requires two observed classes.")
    for (i in seq_len(bootstrap)) {
      index <- unlist(lapply(classes, function(x) sample(x, length(x), replace = TRUE)), use.names = FALSE)
      draws[[i]] <- gazepoint_classification_metrics(
        truth[index], probability[index],
        if (is.null(prediction)) NULL else prediction[index],
        task$positive, threshold
      )
    }
  } else {
    for (i in seq_len(bootstrap)) {
      index <- sample.int(n, n, replace = TRUE)
      draws[[i]] <- gazepoint_regression_metrics(truth[index], prediction[index])
    }
  }
  draws <- .gp3ml_bind_rows(draws)
  metric_columns <- names(draws)[vapply(draws, is.numeric, logical(1))]
  metric_columns <- setdiff(metric_columns, c("n", "threshold"))
  alpha <- (1 - conf_level) / 2
  intervals <- data.frame(
    metric = metric_columns,
    estimate = vapply(metric_columns, function(name) as.numeric(point[[name]][[1L]]), numeric(1)),
    lower = vapply(metric_columns, function(name) as.numeric(stats::quantile(draws[[name]], alpha, na.rm = TRUE)), numeric(1)),
    upper = vapply(metric_columns, function(name) as.numeric(stats::quantile(draws[[name]], 1 - alpha, na.rm = TRUE)), numeric(1)),
    stringsAsFactors = FALSE
  )
  structure(
    list(point = point, intervals = intervals, draws = draws, bootstrap = bootstrap, conf_level = conf_level, seed = seed, task = task),
    class = "gp3ml_metric_uncertainty"
  )
}

#' @method print gp3ml_metric_uncertainty
#' @export
print.gp3ml_metric_uncertainty <- function(x, ...) {
  cat("<gp3ml_metric_uncertainty> bootstrap=", x$bootstrap, " confidence=", x$conf_level, "\n", sep = "")
  print(x$intervals, row.names = FALSE)
  invisible(x)
}
