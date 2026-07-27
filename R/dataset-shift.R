.gp3ml_numeric_shift_row <- function(name, development, external, thresholds) {
  d <- development[[name]]
  e <- external[[name]]
  d_ok <- d[is.finite(d)]
  e_ok <- e[is.finite(e)]
  sd_pool <- sqrt((stats::var(d_ok) + stats::var(e_ok)) / 2)
  smd <- if (is.finite(sd_pool) && sd_pool > 0) (mean(e_ok) - mean(d_ok)) / sd_pool else 0
  outside <- if (length(d_ok) && length(e_ok)) mean(e_ok < min(d_ok) | e_ok > max(d_ok)) else NA_real_
  ks <- if (length(unique(d_ok)) > 1L && length(unique(e_ok)) > 1L)
    suppressWarnings(stats::ks.test(d_ok, e_ok)$statistic[[1L]]) else NA_real_
  severity <- "pass"
  if (abs(smd) >= thresholds$smd_fail || (!is.na(outside) && outside >= thresholds$outside_fail)) severity <- "fail"
  else if (abs(smd) >= thresholds$smd_review || (!is.na(outside) && outside >= thresholds$outside_review)) severity <- "review"
  data.frame(
    predictor = name, type = "numeric",
    development_n = length(d_ok), external_n = length(e_ok),
    development_missing = mean(is.na(d)), external_missing = mean(is.na(e)),
    mean_development = mean(d_ok), mean_external = mean(e_ok),
    standardized_difference = smd, distribution_statistic = ks,
    support_overlap = if (is.na(outside)) NA_real_ else 1 - outside,
    outside_training_range = outside, novel_levels = "",
    status = severity, stringsAsFactors = FALSE
  )
}

.gp3ml_categorical_shift_row <- function(name, development, external, thresholds) {
  d <- as.character(development[[name]])
  e <- as.character(external[[name]])
  levels_all <- sort(unique(c(d[!is.na(d)], e[!is.na(e)])))
  pd <- prop.table(table(factor(d, levels = levels_all), useNA = "no"))
  pe <- prop.table(table(factor(e, levels = levels_all), useNA = "no"))
  tv <- 0.5 * sum(abs(as.numeric(pd) - as.numeric(pe)))
  novel <- setdiff(unique(e[!is.na(e)]), unique(d[!is.na(d)]))
  severity <- if (length(novel) || tv >= thresholds$tv_fail) "fail" else if (tv >= thresholds$tv_review) "review" else "pass"
  data.frame(
    predictor = name, type = "categorical",
    development_n = sum(!is.na(d)), external_n = sum(!is.na(e)),
    development_missing = mean(is.na(d)), external_missing = mean(is.na(e)),
    mean_development = NA_real_, mean_external = NA_real_,
    standardized_difference = NA_real_, distribution_statistic = tv,
    support_overlap = 1 - tv, outside_training_range = NA_real_,
    novel_levels = paste(sort(novel), collapse = ", "),
    status = severity, stringsAsFactors = FALSE
  )
}

#' Audit predictor distribution shift
#'
#' @param development Development/training data.
#' @param external Independent or later data to compare.
#' @param predictors Predictors to audit. Defaults to common columns.
#' @param thresholds Named threshold list.
#' @return A `gp3ml_dataset_shift_audit`.
#' @export
audit_gazepoint_dataset_shift <- function(
    development,
    external,
    predictors = intersect(names(development), names(external)),
    thresholds = list(
      smd_review = 0.20,
      smd_fail = 0.50,
      outside_review = 0.05,
      outside_fail = 0.20,
      tv_review = 0.20,
      tv_fail = 0.40
    )) {
  .gp3ml_ng_assert_data(development, "development")
  .gp3ml_ng_assert_data(external, "external")
  predictors <- unique(as.character(predictors))
  missing <- setdiff(predictors, intersect(names(development), names(external)))
  if (length(missing)) .gp3ml_ng_stop("Predictors absent from one dataset: %s.", paste(missing, collapse = ", "))
  defaults <- list(smd_review=.20, smd_fail=.50, outside_review=.05, outside_fail=.20, tv_review=.20, tv_fail=.40)
  for (nm in names(defaults)) if (is.null(thresholds[[nm]])) thresholds[[nm]] <- defaults[[nm]]
  rows <- lapply(predictors, function(name) {
    if (is.numeric(development[[name]]) && is.numeric(external[[name]])) {
      .gp3ml_numeric_shift_row(name, development, external, thresholds)
    } else {
      .gp3ml_categorical_shift_row(name, development, external, thresholds)
    }
  })
  findings <- if (length(rows)) do.call(rbind, rows) else data.frame()
  structure(
    list(
      status = if (!nrow(findings)) "review" else .gp3ml_ng_status(findings$status),
      findings = findings,
      thresholds = thresholds,
      terminology = c("schema shift", "missingness shift", "covariate shift",
                      "prevalence shift", "calibration drift", "performance degradation"),
      note = "Predictor-distribution shift is reported separately from outcome prevalence, calibration, and performance."
    ),
    class = "gp3ml_dataset_shift_audit"
  )
}

#' Audit missingness shift
#' @param development Development data.
#' @param external External/new data.
#' @param predictors Predictors to audit.
#' @param review_delta Review threshold for absolute missingness change.
#' @param fail_delta Fail threshold for absolute missingness change.
#' @return A `gp3ml_missingness_shift_audit`.
#' @export
audit_gazepoint_missingness_shift <- function(
    development,
    external,
    predictors = intersect(names(development), names(external)),
    review_delta = 0.10,
    fail_delta = 0.25) {
  .gp3ml_ng_assert_data(development, "development")
  .gp3ml_ng_assert_data(external, "external")
  predictors <- unique(as.character(predictors))
  rows <- lapply(predictors, function(name) {
    if (!name %in% names(development) || !name %in% names(external))
      .gp3ml_ng_stop("Predictor `%s` is absent from one dataset.", name)
    d <- mean(is.na(development[[name]]))
    e <- mean(is.na(external[[name]]))
    delta <- e - d
    status <- if (abs(delta) >= fail_delta) "fail" else if (abs(delta) >= review_delta) "review" else "pass"
    data.frame(predictor=name, development_missing=d, external_missing=e,
               delta=delta, status=status, stringsAsFactors=FALSE)
  })
  findings <- if (length(rows)) do.call(rbind, rows) else data.frame()
  structure(
    list(status = if (!nrow(findings)) "review" else .gp3ml_ng_status(findings$status),
         findings = findings, review_delta=review_delta, fail_delta=fail_delta),
    class = "gp3ml_missingness_shift_audit"
  )
}

#' Summarize dataset shift without collapsing it to one drift score
#' @param shift A dataset-shift audit.
#' @param missingness Optional missingness-shift audit.
#' @return A structured summary.
#' @export
summarize_gazepoint_shift <- function(shift, missingness = NULL) {
  if (!inherits(shift, "gp3ml_dataset_shift_audit")) .gp3ml_ng_stop("`shift` must be a dataset-shift audit.")
  counts <- as.data.frame(table(shift$findings$status), stringsAsFactors = FALSE)
  names(counts) <- c("status", "n_predictors")
  out <- list(dataset_shift_status = shift$status, dataset_shift_counts = counts)
  if (!is.null(missingness)) {
    if (!inherits(missingness, "gp3ml_missingness_shift_audit")) .gp3ml_ng_stop("Invalid missingness audit.")
    mcounts <- as.data.frame(table(missingness$findings$status), stringsAsFactors = FALSE)
    names(mcounts) <- c("status", "n_predictors")
    out$missingness_shift_status <- missingness$status
    out$missingness_shift_counts <- mcounts
  }
  structure(out, class = "gp3ml_shift_summary")
}

#' Plot a dataset shift audit
#' @param x A `gp3ml_dataset_shift_audit`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_dataset_shift_audit
#' @export
plot.gp3ml_dataset_shift_audit <- function(x, ...) {
  tab <- x$findings
  if (!nrow(tab)) .gp3ml_ng_stop("No predictor shift findings are available.")
  magnitude <- ifelse(tab$type == "numeric", abs(tab$standardized_difference),
                      tab$distribution_statistic)
  names(magnitude) <- tab$predictor
  graphics::barplot(magnitude, horiz = TRUE, las = 1,
                    xlab = "Shift magnitude (SMD or total variation)",
                    main = "Predictor distribution shift", ...)
  invisible(x)
}
