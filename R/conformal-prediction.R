#' Fit target-aware split-conformal calibration
#'
#' This function provides conservative split-conformal calibration for
#' explicitly observed regression or binary classification outcomes. When a
#' grouped calibration unit is supplied, row scores are aggregated to the
#' maximum score within each calibration unit before the conformal quantile is
#' estimated. This records and respects the calibration unit but does not claim
#' distribution-free coverage under arbitrary dependence.
#'
#' @param truth Observed calibration outcomes.
#' @param prediction Numeric predictions for regression.
#' @param probability Positive-class probabilities for classification.
#' @param task_type `"regression"` or `"classification"`.
#' @param positive Positive class label for classification.
#' @param level Nominal coverage level.
#' @param calibration_unit Calibration unit.
#' @param unit Optional group identifier for grouped calibration.
#' @param generalization_target Declared generalization target.
#' @return A `gp3ml_conformal_fit`.
#' @export
fit_gazepoint_conformal <- function(
    truth,
    prediction = NULL,
    probability = NULL,
    task_type = c("regression", "classification"),
    positive = NULL,
    level = 0.90,
    calibration_unit = c("observation", "participant", "stimulus", "participant_stimulus"),
    unit = NULL,
    generalization_target) {
  task_type <- match.arg(task_type)
  calibration_unit <- match.arg(calibration_unit)
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1) {
    .gp3ml_ng_stop("`level` must be strictly between 0 and 1.")
  }
  n <- length(truth)
  if (task_type == "regression") {
    if (is.null(prediction) || length(prediction) != n || !is.numeric(prediction))
      .gp3ml_ng_stop("Regression conformal calibration requires numeric `prediction` aligned with `truth`.")
    keep <- !is.na(truth) & !is.na(prediction)
    score <- abs(as.numeric(truth[keep]) - prediction[keep])
  } else {
    if (is.null(probability) || length(probability) != n)
      .gp3ml_ng_stop("Classification conformal calibration requires `probability` aligned with `truth`.")
    .gp3ml_ng_assert_prob(probability)
    truth_chr <- as.character(truth)
    levels_found <- sort(unique(truth_chr[!is.na(truth_chr)]))
    if (length(levels_found) != 2L || is.null(positive) || !positive %in% levels_found)
      .gp3ml_ng_stop("Binary classification requires exactly two truth levels and explicit `positive`.")
    keep <- !is.na(truth_chr) & !is.na(probability)
    p_true <- ifelse(truth_chr[keep] == positive, probability[keep], 1 - probability[keep])
    score <- 1 - p_true
  }

  unit_kept <- if (is.null(unit)) NULL else as.character(unit[keep])
  if (calibration_unit != "observation") {
    if (is.null(unit_kept) || length(unit_kept) != length(score) || anyNA(unit_kept)) {
      .gp3ml_ng_stop("Grouped conformal calibration requires a complete `unit` identifier.")
    }
    split_scores <- split(score, unit_kept)
    score_for_quantile <- vapply(split_scores, max, numeric(1), na.rm = TRUE)
  } else {
    score_for_quantile <- score
  }

  m <- length(score_for_quantile)
  probability_index <- min(1, ceiling((m + 1) * level) / m)
  q <- .gp3ml_ng_quantile(score_for_quantile, probability_index)

  structure(
    list(
      task_type = task_type,
      positive = positive,
      negative = if (task_type == "classification") setdiff(levels_found, positive)[[1L]] else NULL,
      level = level,
      calibration_unit = calibration_unit,
      generalization_target = as.character(generalization_target),
      n_rows = length(score),
      n_calibration_units = m,
      quantile_probability = probability_index,
      conformity_quantile = q,
      score_summary = stats::quantile(score_for_quantile, probs = c(0, .25, .5, .75, 1),
                                      na.rm = TRUE, names = TRUE),
      caveat = "Coverage claims require exchangeability assumptions appropriate to the declared calibration unit and generalization target."
    ),
    class = "gp3ml_conformal_fit"
  )
}

#' Predict conformal regression intervals
#' @param object A regression `gp3ml_conformal_fit`.
#' @param prediction Point predictions.
#' @return Data frame with point prediction, lower, and upper limits.
#' @export
predict_gazepoint_interval <- function(object, prediction) {
  validation <- validate_gazepoint_conformal(object)
  if (!identical(validation$status, "pass") || object$task_type != "regression")
    .gp3ml_ng_stop("A valid regression conformal fit is required.")
  prediction <- as.numeric(prediction)
  data.frame(
    prediction = prediction,
    lower = prediction - object$conformity_quantile,
    upper = prediction + object$conformity_quantile
  )
}

#' Predict binary conformal prediction sets
#' @param object A classification `gp3ml_conformal_fit`.
#' @param probability Positive-class probabilities.
#' @return A data frame containing set membership and a readable set label.
#' @export
predict_gazepoint_set <- function(object, probability) {
  validation <- validate_gazepoint_conformal(object)
  if (!identical(validation$status, "pass") || object$task_type != "classification")
    .gp3ml_ng_stop("A valid classification conformal fit is required.")
  .gp3ml_ng_assert_prob(probability)
  q <- object$conformity_quantile
  include_positive <- (1 - probability) <= q
  include_negative <- probability <= q
  label <- ifelse(
    include_positive & include_negative,
    paste0("{", object$negative, ", ", object$positive, "}"),
    ifelse(include_positive, paste0("{", object$positive, "}"),
           ifelse(include_negative, paste0("{", object$negative, "}"), "{}"))
  )
  data.frame(
    probability = probability,
    include_negative = include_negative,
    include_positive = include_positive,
    set = label,
    stringsAsFactors = FALSE
  )
}

#' Assess conformal coverage
#' @param object A `gp3ml_conformal_fit`.
#' @param truth Observed outcomes.
#' @param interval Regression interval data frame.
#' @param set Classification set data frame.
#' @param unit Optional assessment-unit identifier.
#' @return A `gp3ml_conformal_coverage`.
#' @export
assess_gazepoint_conformal_coverage <- function(
    object,
    truth,
    interval = NULL,
    set = NULL,
    unit = NULL) {
  if (object$task_type == "regression") {
    if (is.null(interval) || !all(c("lower", "upper") %in% names(interval)) ||
        nrow(interval) != length(truth))
      .gp3ml_ng_stop("Supply regression `interval` rows aligned with `truth`.")
    covered <- !is.na(truth) & !is.na(interval$lower) & !is.na(interval$upper) &
      as.numeric(truth) >= interval$lower & as.numeric(truth) <= interval$upper
  } else {
    if (is.null(set) || !all(c("include_negative", "include_positive") %in% names(set)) ||
        nrow(set) != length(truth))
      .gp3ml_ng_stop("Supply classification `set` rows aligned with `truth`.")
    truth_chr <- as.character(truth)
    covered <- ifelse(
      truth_chr == object$positive,
      set$include_positive,
      ifelse(truth_chr == object$negative, set$include_negative, FALSE)
    )
    covered[is.na(truth_chr)] <- FALSE
  }
  row_coverage <- mean(covered)
  by_unit <- NULL
  unit_coverage <- NA_real_
  if (!is.null(unit)) {
    if (length(unit) != length(covered) || anyNA(unit)) .gp3ml_ng_stop("`unit` must be complete and aligned.")
    split_cov <- split(covered, as.character(unit))
    all_covered <- vapply(split_cov, all, logical(1))
    by_unit <- data.frame(unit = names(all_covered), all_rows_covered = unname(all_covered),
                          stringsAsFactors = FALSE)
    unit_coverage <- mean(all_covered)
  }
  status <- if (row_coverage + 1e-12 >= object$level) "pass" else "review"
  structure(
    list(
      status = status,
      nominal_coverage = object$level,
      row_coverage = row_coverage,
      unit_coverage = unit_coverage,
      calibration_unit = object$calibration_unit,
      generalization_target = object$generalization_target,
      by_unit = by_unit,
      caveat = object$caveat
    ),
    class = "gp3ml_conformal_coverage"
  )
}

#' Validate a conformal fit
#' @param object A conformal fit.
#' @return A validation object.
#' @export
validate_gazepoint_conformal <- function(object) {
  checks <- data.frame(
    check = c("class", "task_type", "level", "calibration_unit", "quantile", "target", "unit_count"),
    status = "pass",
    stringsAsFactors = FALSE
  )
  if (!inherits(object, "gp3ml_conformal_fit")) {
    checks$status[] <- "fail"
  } else {
    if (!object$task_type %in% c("classification", "regression"))
      checks$status[checks$check == "task_type"] <- "fail"
    if (!is.numeric(object$level) || object$level <= 0 || object$level >= 1)
      checks$status[checks$check == "level"] <- "fail"
    if (!object$calibration_unit %in% c("observation", "participant", "stimulus", "participant_stimulus"))
      checks$status[checks$check == "calibration_unit"] <- "fail"
    if (!is.numeric(object$conformity_quantile) || length(object$conformity_quantile) != 1L ||
        !is.finite(object$conformity_quantile))
      checks$status[checks$check == "quantile"] <- "fail"
    if (!is.character(object$generalization_target) || !nzchar(object$generalization_target))
      checks$status[checks$check == "target"] <- "fail"
    if (!is.numeric(object$n_calibration_units) || object$n_calibration_units < 2)
      checks$status[checks$check == "unit_count"] <- "review"
  }
  structure(list(status = .gp3ml_ng_status(checks$status), checks = checks),
            class = "gp3ml_conformal_validation")
}

#' Plot conformal coverage
#' @param x A `gp3ml_conformal_coverage`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_conformal_coverage
#' @export
plot.gp3ml_conformal_coverage <- function(x, ...) {
  values <- c(nominal = x$nominal_coverage, row = x$row_coverage)
  if (is.finite(x$unit_coverage)) values <- c(values, unit = x$unit_coverage)
  graphics::barplot(values, ylim = c(0, 1), ylab = "Coverage",
                    main = "Conformal coverage audit", ...)
  invisible(x)
}
