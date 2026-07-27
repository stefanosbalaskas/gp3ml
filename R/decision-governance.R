#' Create a governed classification decision rule
#'
#' @param metric Metric used to justify the threshold.
#' @param direction Either `"maximize"` or `"minimize"`.
#' @param threshold Optional probability threshold. Leave `NULL` until selected.
#' @param threshold_origin Origin of the threshold.
#' @param cost_false_positive Non-negative false-positive cost.
#' @param cost_false_negative Non-negative false-negative cost.
#' @param abstention_allowed Whether abstention is permitted.
#' @param abstention_interval Optional length-two probability interval. Probabilities
#'   inside the interval are labelled as abstentions.
#' @param calibration_source Description of the calibration source.
#' @param training_partition Description of the data partition used to determine
#'   the threshold.
#' @param generalization_target Declared generalization target.
#' @param scientific_justification Explicit scientific justification.
#' @return A `gp3ml_decision_rule`.
#' @export
create_gazepoint_decision_rule <- function(
    metric,
    direction = c("maximize", "minimize"),
    threshold = NULL,
    threshold_origin = c("predeclared", "training", "inner_resampling"),
    cost_false_positive = 1,
    cost_false_negative = 1,
    abstention_allowed = FALSE,
    abstention_interval = NULL,
    calibration_source = "none",
    training_partition = "analysis",
    generalization_target,
    scientific_justification) {
  direction <- match.arg(direction)
  threshold_origin <- match.arg(threshold_origin)
  if (!is.character(metric) || length(metric) != 1L || !nzchar(metric)) {
    .gp3ml_ng_stop("`metric` must be one non-empty metric name.")
  }
  if (!is.null(threshold) && (!is.numeric(threshold) || length(threshold) != 1L ||
      !is.finite(threshold) || threshold <= 0 || threshold >= 1)) {
    .gp3ml_ng_stop("`threshold` must be NULL or one probability strictly between 0 and 1.")
  }
  if (any(c(cost_false_positive, cost_false_negative) < 0) ||
      any(!is.finite(c(cost_false_positive, cost_false_negative)))) {
    .gp3ml_ng_stop("Decision costs must be finite and non-negative.")
  }
  if (isTRUE(abstention_allowed)) {
    if (is.null(abstention_interval) || length(abstention_interval) != 2L ||
        any(!is.finite(abstention_interval)) ||
        abstention_interval[[1L]] < 0 || abstention_interval[[2L]] > 1 ||
        abstention_interval[[1L]] >= abstention_interval[[2L]]) {
      .gp3ml_ng_stop("Abstention requires an ordered length-two interval inside [0, 1].")
    }
  } else {
    abstention_interval <- NULL
  }
  if (!is.character(scientific_justification) || length(scientific_justification) != 1L ||
      !nzchar(trimws(scientific_justification))) {
    .gp3ml_ng_stop("Supply one explicit `scientific_justification`.")
  }

  structure(
    list(
      metric = metric,
      direction = direction,
      threshold = threshold,
      threshold_origin = threshold_origin,
      cost_false_positive = as.numeric(cost_false_positive),
      cost_false_negative = as.numeric(cost_false_negative),
      abstention_allowed = isTRUE(abstention_allowed),
      abstention_interval = abstention_interval,
      calibration_source = as.character(calibration_source),
      training_partition = as.character(training_partition),
      generalization_target = as.character(generalization_target),
      scientific_justification = scientific_justification
    ),
    class = "gp3ml_decision_rule"
  )
}

#' Validate a governed decision rule
#' @param rule A `gp3ml_decision_rule`.
#' @param require_threshold Whether a concrete threshold is required.
#' @return A validation object.
#' @export
validate_gazepoint_decision_rule <- function(rule, require_threshold = FALSE) {
  checks <- data.frame(
    check = c(
      "class",
      "metric",
      "direction",
      "threshold",
      "threshold_origin",
      "training_partition",
      "generalization_target",
      "scientific_justification",
      "abstention"
    ),
    status = "pass",
    detail = "",
    stringsAsFactors = FALSE
  )
  if (!inherits(rule, "gp3ml_decision_rule")) {
    checks$status[checks$check == "class"] <- "fail"
  } else {
    if (!is.character(rule$metric) || length(rule$metric) != 1L || !nzchar(rule$metric))
      checks$status[checks$check == "metric"] <- "fail"
    if (!rule$direction %in% c("maximize", "minimize"))
      checks$status[checks$check == "direction"] <- "fail"
    threshold_ok <- is.null(rule$threshold) ||
      (is.numeric(rule$threshold) && length(rule$threshold) == 1L &&
         is.finite(rule$threshold) && rule$threshold > 0 && rule$threshold < 1)
    if (!threshold_ok || (isTRUE(require_threshold) && is.null(rule$threshold)))
      checks$status[checks$check == "threshold"] <- "fail"
    if (!rule$threshold_origin %in% c("predeclared", "training", "inner_resampling"))
      checks$status[checks$check == "threshold_origin"] <- "fail"
    if (identical(rule$training_partition, "assessment") ||
        grepl("external", tolower(rule$training_partition), fixed = TRUE))
      checks$status[checks$check == "training_partition"] <- "fail"
    if (!is.character(rule$generalization_target) || !nzchar(rule$generalization_target))
      checks$status[checks$check == "generalization_target"] <- "fail"
    if (!is.character(rule$scientific_justification) || !nzchar(trimws(rule$scientific_justification)))
      checks$status[checks$check == "scientific_justification"] <- "fail"
    if (isTRUE(rule$abstention_allowed)) {
      z <- rule$abstention_interval
      if (is.null(z) || length(z) != 2L || z[[1L]] >= z[[2L]])
        checks$status[checks$check == "abstention"] <- "fail"
    }
  }
  structure(
    list(status = .gp3ml_ng_status(checks$status), checks = checks),
    class = "gp3ml_decision_rule_validation"
  )
}

#' Evaluate explicit classification thresholds
#'
#' @param truth Observed binary outcome.
#' @param probability Probability of the positive class.
#' @param positive Positive class label.
#' @param thresholds Explicit candidate thresholds.
#' @param cost_false_positive False-positive cost.
#' @param cost_false_negative False-negative cost.
#' @return A `gp3ml_threshold_evaluation`.
#' @export
evaluate_gazepoint_thresholds <- function(
    truth,
    probability,
    positive,
    thresholds,
    cost_false_positive = 1,
    cost_false_negative = 1) {
  .gp3ml_ng_assert_prob(probability)
  if (missing(thresholds) || !length(thresholds)) {
    .gp3ml_ng_stop("Supply explicit candidate `thresholds`; gp3ml does not choose a hidden default.")
  }
  thresholds <- sort(unique(as.numeric(thresholds)))
  if (any(!is.finite(thresholds)) || any(thresholds <= 0 | thresholds >= 1)) {
    .gp3ml_ng_stop("All candidate thresholds must be strictly between 0 and 1.")
  }
  keep <- !is.na(truth) & !is.na(probability)
  truth <- as.character(truth[keep])
  probability <- probability[keep]
  positive <- as.character(positive)
  levels_found <- sort(unique(truth))
  if (length(levels_found) != 2L || !positive %in% levels_found) {
    .gp3ml_ng_stop("`truth` must contain exactly two observed levels and `positive` must identify one.")
  }
  negative <- setdiff(levels_found, positive)[[1L]]
  rows <- lapply(thresholds, function(th) {
    predicted <- ifelse(probability >= th, positive, negative)
    tp <- sum(predicted == positive & truth == positive)
    tn <- sum(predicted == negative & truth == negative)
    fp <- sum(predicted == positive & truth == negative)
    fn <- sum(predicted == negative & truth == positive)
    sensitivity <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_
    specificity <- if ((tn + fp) > 0) tn / (tn + fp) else NA_real_
    precision <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
    recall <- sensitivity
    f1 <- if (is.finite(precision) && is.finite(recall) && (precision + recall) > 0)
      2 * precision * recall / (precision + recall) else NA_real_
    accuracy <- (tp + tn) / length(truth)
    balanced_accuracy <- mean(c(sensitivity, specificity), na.rm = TRUE)
    expected_cost <- (fp * cost_false_positive + fn * cost_false_negative) / length(truth)
    data.frame(
      threshold = th, tp = tp, tn = tn, fp = fp, fn = fn,
      sensitivity = sensitivity, specificity = specificity,
      precision = precision, f1 = f1, accuracy = accuracy,
      balanced_accuracy = balanced_accuracy, expected_cost = expected_cost,
      stringsAsFactors = FALSE
    )
  })
  structure(
    list(
      positive = positive,
      negative = negative,
      n = length(truth),
      thresholds = do.call(rbind, rows),
      cost_false_positive = cost_false_positive,
      cost_false_negative = cost_false_negative
    ),
    class = "gp3ml_threshold_evaluation"
  )
}

#' Select a threshold from a governed threshold evaluation
#'
#' @param evaluation A `gp3ml_threshold_evaluation`.
#' @param metric Metric column to optimize.
#' @param direction `"maximize"` or `"minimize"`.
#' @param threshold_origin Must identify an analysis/training source.
#' @param training_partition Partition used to select the threshold.
#' @param generalization_target Declared target.
#' @param scientific_justification Explicit justification.
#' @param abstention_allowed Whether abstention is allowed.
#' @param abstention_interval Optional abstention interval.
#' @return A `gp3ml_decision_rule`.
#' @export
select_gazepoint_threshold <- function(
    evaluation,
    metric,
    direction = c("maximize", "minimize"),
    threshold_origin = c("inner_resampling", "training"),
    training_partition = "inner_resampling",
    generalization_target,
    scientific_justification,
    abstention_allowed = FALSE,
    abstention_interval = NULL) {
  if (!inherits(evaluation, "gp3ml_threshold_evaluation")) {
    .gp3ml_ng_stop("`evaluation` must come from `evaluate_gazepoint_thresholds()`.")
  }
  direction <- match.arg(direction)
  threshold_origin <- match.arg(threshold_origin)
  tab <- evaluation$thresholds
  if (!metric %in% names(tab)) .gp3ml_ng_stop("Unknown threshold metric `%s`.", metric)
  values <- tab[[metric]]
  if (!is.numeric(values) || all(!is.finite(values))) .gp3ml_ng_stop("Metric `%s` has no finite values.", metric)
  target <- if (direction == "maximize") max(values, na.rm = TRUE) else min(values, na.rm = TRUE)
  candidates <- tab[is.finite(values) & values == target, , drop = FALSE]
  selected <- candidates$threshold[[which.min(candidates$threshold)]]
  create_gazepoint_decision_rule(
    metric = metric,
    direction = direction,
    threshold = selected,
    threshold_origin = threshold_origin,
    cost_false_positive = evaluation$cost_false_positive,
    cost_false_negative = evaluation$cost_false_negative,
    abstention_allowed = abstention_allowed,
    abstention_interval = abstention_interval,
    calibration_source = "explicit threshold evaluation",
    training_partition = training_partition,
    generalization_target = generalization_target,
    scientific_justification = scientific_justification
  )
}

#' Apply a governed classification decision rule
#' @param rule A validated decision rule.
#' @param probability Positive-class probability.
#' @param positive Positive class label.
#' @param negative Negative class label.
#' @param abstain_label Label used for abstentions.
#' @return A factor of governed decisions.
#' @export
apply_gazepoint_decision_rule <- function(
    rule,
    probability,
    positive,
    negative,
    abstain_label = ".abstain") {
  validation <- validate_gazepoint_decision_rule(rule, require_threshold = TRUE)
  if (!identical(validation$status, "pass")) .gp3ml_ng_stop("Decision rule validation failed.")
  .gp3ml_ng_assert_prob(probability)
  decision <- ifelse(probability >= rule$threshold, positive, negative)
  if (isTRUE(rule$abstention_allowed)) {
    inside <- probability >= rule$abstention_interval[[1L]] &
      probability <= rule$abstention_interval[[2L]]
    decision[inside] <- abstain_label
  }
  factor(decision, levels = unique(c(negative, positive, abstain_label)))
}

#' Audit abstention decisions
#' @param truth Observed binary outcome.
#' @param decision Decisions returned by `apply_gazepoint_decision_rule()`.
#' @param abstain_label Abstention label.
#' @return A `gp3ml_abstention_audit`.
#' @export
audit_gazepoint_abstention <- function(truth, decision, abstain_label = ".abstain") {
  if (length(truth) != length(decision)) .gp3ml_ng_stop("`truth` and `decision` lengths differ.")
  keep <- !is.na(truth) & !is.na(decision)
  truth <- as.character(truth[keep])
  decision <- as.character(decision[keep])
  abstained <- decision == abstain_label
  covered <- !abstained
  coverage <- mean(covered)
  error_rate <- if (any(covered)) mean(decision[covered] != truth[covered]) else NA_real_
  abstention_rate <- mean(abstained)
  by_truth <- data.frame(
    truth = sort(unique(truth)),
    n = as.integer(table(factor(truth, levels = sort(unique(truth))))),
    stringsAsFactors = FALSE
  )
  by_truth$abstained <- vapply(by_truth$truth, function(z) sum(abstained & truth == z), integer(1))
  by_truth$abstention_rate <- by_truth$abstained / by_truth$n
  structure(
    list(
      status = if (coverage == 0) "fail" else "pass",
      n = length(truth),
      coverage = coverage,
      abstention_rate = abstention_rate,
      covered_error_rate = error_rate,
      by_truth = by_truth
    ),
    class = "gp3ml_abstention_audit"
  )
}

#' @method print gp3ml_decision_rule
#' @export
print.gp3ml_decision_rule <- function(x, ...) {
  cat("gp3ml decision rule\n")
  cat(" metric: ", x$metric, " (", x$direction, ")\n", sep = "")
  cat(" threshold: ", if (is.null(x$threshold)) "<not selected>" else format(x$threshold), "\n", sep = "")
  cat(" origin: ", x$threshold_origin, "\n", sep = "")
  cat(" target: ", x$generalization_target, "\n", sep = "")
  cat(" abstention: ", if (isTRUE(x$abstention_allowed)) "enabled" else "disabled", "\n", sep = "")
  invisible(x)
}

#' Plot threshold evaluation
#' @param x A `gp3ml_threshold_evaluation`.
#' @param metric Metric to plot.
#' @param ... Additional arguments passed to `graphics::plot()`.
#' @method plot gp3ml_threshold_evaluation
#' @export
plot.gp3ml_threshold_evaluation <- function(x, metric = "balanced_accuracy", ...) {
  if (!metric %in% names(x$thresholds)) .gp3ml_ng_stop("Unknown metric `%s`.", metric)
  graphics::plot(
    x$thresholds$threshold,
    x$thresholds[[metric]],
    type = "b",
    xlab = "Decision threshold",
    ylab = metric,
    main = paste("Threshold evaluation:", metric),
    ...
  )
  invisible(x)
}

#' Plot abstention audit
#' @param x A `gp3ml_abstention_audit`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_abstention_audit
#' @export
plot.gp3ml_abstention_audit <- function(x, ...) {
  values <- c(coverage = x$coverage, abstention = x$abstention_rate,
              covered_error = x$covered_error_rate)
  graphics::barplot(values, ylim = c(0, 1), ylab = "Proportion",
                    main = "Governed abstention audit", ...)
  invisible(x)
}
