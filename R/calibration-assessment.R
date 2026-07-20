#' Fit a probability calibrator
#'
#' @param truth Observed binary outcome values.
#' @param probability Uncalibrated positive-class probabilities.
#' @param positive Label representing the positive class.
#' @param method Calibration method: Platt scaling or isotonic regression.
#' @export
fit_gazepoint_calibrator <- function(truth, probability, positive = NULL, method = c("platt", "isotonic")) {
  method <- match.arg(method)
  binary <- .gp3ml_binary_values(truth, positive)
  y <- binary$y; p <- .gp3ml_clip_probability(probability)
  fit <- if (method == "platt") stats::glm(y ~ stats::qlogis(p), family = stats::binomial()) else stats::isoreg(p, y)
  structure(list(method = method, fit = fit, positive = binary$positive, negative = binary$negative), class = "gp3ml_calibrator")
}

#' Apply a fitted probability calibrator
#'
#' @param calibrator A fitted `gp3ml_calibrator` object.
#' @param probability Uncalibrated probabilities to transform.
#' @export
apply_gazepoint_calibrator <- function(calibrator, probability) {
  p <- .gp3ml_clip_probability(probability)
  result <- if (calibrator$method == "platt") {
    as.numeric(stats::predict(calibrator$fit, newdata = data.frame(p = p), type = "response"))
  } else {
    stats::approx(calibrator$fit$x, calibrator$fit$yf, xout = p, rule = 2, ties = "ordered")$y
  }
  .gp3ml_clip_probability(result)
}

.gp3ml_calibration_core <- function(y, p, bins) {
  p <- .gp3ml_clip_probability(p)
  fit <- tryCatch(stats::glm(y ~ stats::qlogis(p), family = stats::binomial()), error = function(e) NULL)
  breaks <- seq(0, 1, length.out = bins + 1L)
  bin <- cut(p, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  reliability <- do.call(rbind, lapply(split(seq_along(p), bin), function(index) data.frame(bin = bin[index[[1L]]], n = length(index), mean_probability = mean(p[index]), observed_rate = mean(y[index]))))
  ece <- sum(reliability$n / sum(reliability$n) * abs(reliability$mean_probability - reliability$observed_rate))
  list(summary = data.frame(intercept = if (is.null(fit)) NA_real_ else stats::coef(fit)[[1L]], slope = if (is.null(fit)) NA_real_ else stats::coef(fit)[[2L]], brier = mean((p - y)^2), log_loss = -mean(y * log(p) + (1 - y) * log(1 - p)), ece = ece), reliability = reliability)
}

#' Calibration assessment with bootstrap uncertainty
#'
#' @param truth Observed binary outcome values.
#' @param probability Predicted positive-class probabilities.
#' @param positive Label representing the positive class.
#' @param bins Number of reliability bins.
#' @param bootstrap Number of bootstrap replicates.
#' @param conf_level Confidence level for percentile intervals.
#' @param seed Deterministic random seed.
#' @export
assess_gazepoint_calibration <- function(truth, probability, positive = NULL, bins = 10L, bootstrap = 200L, conf_level = 0.95, seed = 1L) {
  binary <- .gp3ml_binary_values(truth, positive)
  y <- binary$y; p <- .gp3ml_clip_probability(probability)
  core <- .gp3ml_calibration_core(y, p, bins)
  restore <- .gp3ml_set_seed(seed); on.exit(restore(), add = TRUE)
  bootstrap <- as.integer(bootstrap)
  draws <- if (bootstrap > 0L) .gp3ml_bind_rows(lapply(seq_len(bootstrap), function(i) {
    index <- sample.int(length(y), replace = TRUE)
    .gp3ml_calibration_core(y[index], p[index], bins)$summary
  })) else data.frame()
  intervals <- data.frame()
  if (nrow(draws)) {
    alpha <- (1 - conf_level) / 2
    intervals <- data.frame(metric = names(draws), lower = vapply(draws, stats::quantile, numeric(1), probs = alpha, na.rm = TRUE), upper = vapply(draws, stats::quantile, numeric(1), probs = 1 - alpha, na.rm = TRUE))
  }
  structure(list(summary = core$summary, reliability = core$reliability, intervals = intervals, positive = binary$positive, bins = bins, bootstrap = bootstrap, seed = seed), class = "gp3ml_calibration_assessment")
}

#' @method print gp3ml_calibration_assessment
#' @export
print.gp3ml_calibration_assessment <- function(x, ...) { cat("<gp3ml_calibration_assessment>\n"); print(x$summary, row.names = FALSE); invisible(x) }
