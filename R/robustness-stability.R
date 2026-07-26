.gp3ml_collect_numeric_metrics <- function(result) {
  if (is.numeric(result) && !is.null(names(result))) return(result)
  if (is.data.frame(result) && nrow(result) == 1L) {
    out <- unlist(result[1, vapply(result, is.numeric, logical(1)), drop=FALSE], use.names=TRUE)
    return(as.numeric(out) |> stats::setNames(names(out)))
  }
  .gp3ml_ng_stop("Evaluator must return a named numeric vector or one-row data frame of numeric metrics.")
}

#' Evaluate seed stability
#' @param seeds Integer seeds.
#' @param evaluator Function called as `evaluator(seed = seed, ...)`.
#' @param ... Additional evaluator arguments.
#' @return A `gp3ml_stability_evaluation`.
#' @export
evaluate_gazepoint_seed_stability <- function(seeds, evaluator, ...) {
  if (!is.function(evaluator)) .gp3ml_ng_stop("`evaluator` must be a function.")
  seeds <- unique(as.integer(seeds))
  rows <- lapply(seeds, function(seed) {
    res <- .gp3ml_collect_numeric_metrics(evaluator(seed=seed, ...))
    data.frame(seed=seed, as.list(res), check.names=FALSE)
  })
  tab <- do.call(rbind, rows)
  metrics <- setdiff(names(tab), "seed")
  ranges <- data.frame(
    metric=metrics,
    minimum=vapply(tab[metrics], min, numeric(1), na.rm=TRUE),
    maximum=vapply(tab[metrics], max, numeric(1), na.rm=TRUE),
    sd=vapply(tab[metrics], stats::sd, numeric(1), na.rm=TRUE),
    stringsAsFactors=FALSE
  )
  structure(list(kind="seed", results=tab, summary=ranges), class="gp3ml_stability_evaluation")
}

#' Evaluate leave-one-feature-out stability
#' @param features Predictor names.
#' @param evaluator Function called as `evaluator(excluded_feature = feature, ...)`.
#' @param ... Additional evaluator arguments.
#' @return A `gp3ml_stability_evaluation`.
#' @export
evaluate_gazepoint_feature_stability <- function(features, evaluator, ...) {
  if (!is.function(evaluator)) .gp3ml_ng_stop("`evaluator` must be a function.")
  features <- unique(as.character(features))
  rows <- lapply(features, function(feature) {
    res <- .gp3ml_collect_numeric_metrics(evaluator(excluded_feature=feature, ...))
    data.frame(excluded_feature=feature, as.list(res), check.names=FALSE)
  })
  tab <- do.call(rbind, rows)
  metrics <- setdiff(names(tab), "excluded_feature")
  ranges <- data.frame(
    metric=metrics,
    minimum=vapply(tab[metrics], min, numeric(1), na.rm=TRUE),
    maximum=vapply(tab[metrics], max, numeric(1), na.rm=TRUE),
    sd=vapply(tab[metrics], stats::sd, numeric(1), na.rm=TRUE),
    stringsAsFactors=FALSE
  )
  structure(list(kind="feature", results=tab, summary=ranges), class="gp3ml_stability_evaluation")
}

#' Evaluate threshold stability around the optimum
#' @param evaluation Threshold evaluation.
#' @param metric Metric.
#' @param direction Optimization direction.
#' @param tolerance Fractional tolerance from the optimum.
#' @return A `gp3ml_threshold_stability`.
#' @export
evaluate_gazepoint_threshold_stability <- function(
    evaluation, metric, direction=c("maximize","minimize"), tolerance=0.02) {
  if (!inherits(evaluation, "gp3ml_threshold_evaluation")) .gp3ml_ng_stop("Invalid threshold evaluation.")
  direction <- match.arg(direction)
  tab <- evaluation$thresholds
  if (!metric %in% names(tab)) .gp3ml_ng_stop("Unknown metric.")
  value <- tab[[metric]]
  optimum <- if (direction=="maximize") max(value, na.rm=TRUE) else min(value, na.rm=TRUE)
  scale <- max(abs(optimum), .Machine$double.eps)
  near <- if (direction=="maximize") value >= optimum - tolerance*scale else value <= optimum + tolerance*scale
  span <- range(tab$threshold[near], na.rm=TRUE)
  structure(
    list(status=if (diff(span) >= 0.10) "stable" else if (diff(span) >= 0.04) "review" else "unstable",
         metric=metric, optimum=optimum, tolerance=tolerance, near_optimal=tab[near,,drop=FALSE],
         threshold_span=span),
    class="gp3ml_threshold_stability"
  )
}

#' Evaluate named missingness-sensitivity scenarios
#' @param scenarios Named list of scenario objects.
#' @param evaluator Function called as `evaluator(scenario = scenario, name = name, ...)`.
#' @param ... Additional evaluator arguments.
#' @return A `gp3ml_stability_evaluation`.
#' @export
evaluate_gazepoint_missingness_sensitivity <- function(scenarios, evaluator, ...) {
  if (!is.list(scenarios) || is.null(names(scenarios)) || any(!nzchar(names(scenarios))))
    .gp3ml_ng_stop("`scenarios` must be a named list.")
  rows <- lapply(names(scenarios), function(name) {
    res <- .gp3ml_collect_numeric_metrics(evaluator(scenario=scenarios[[name]], name=name, ...))
    data.frame(scenario=name, as.list(res), check.names=FALSE)
  })
  tab <- do.call(rbind, rows)
  metrics <- setdiff(names(tab), "scenario")
  ranges <- data.frame(
    metric=metrics,
    minimum=vapply(tab[metrics], min, numeric(1), na.rm=TRUE),
    maximum=vapply(tab[metrics], max, numeric(1), na.rm=TRUE),
    sd=vapply(tab[metrics], stats::sd, numeric(1), na.rm=TRUE),
    stringsAsFactors=FALSE
  )
  structure(list(kind="missingness", results=tab, summary=ranges), class="gp3ml_stability_evaluation")
}

#' Audit multiple robustness dimensions
#'
#' @param seed_stability Optional seed-stability object.
#' @param feature_stability Optional feature-stability object.
#' @param threshold_stability Optional threshold-stability object.
#' @param missingness_stability Optional missingness-stability object.
#' @param relative_sd_review Relative SD threshold for review.
#' @param relative_sd_fail Relative SD threshold for fail.
#' @return A `gp3ml_model_robustness_audit`.
#' @export
audit_gazepoint_model_robustness <- function(
    seed_stability=NULL,
    feature_stability=NULL,
    threshold_stability=NULL,
    missingness_stability=NULL,
    relative_sd_review=0.05,
    relative_sd_fail=0.15) {
  components <- list(seed=seed_stability, feature=feature_stability,
                     threshold=threshold_stability, missingness=missingness_stability)
  rows <- list()
  for (nm in names(components)) {
    obj <- components[[nm]]
    if (is.null(obj)) next
    if (inherits(obj, "gp3ml_threshold_stability")) {
      status <- switch(obj$status, stable="pass", review="review", unstable="fail")
      rows[[length(rows)+1L]] <- data.frame(dimension=nm, metric=obj$metric,
                                           indicator=diff(obj$threshold_span), status=status)
    } else if (inherits(obj, "gp3ml_stability_evaluation")) {
      for (i in seq_len(nrow(obj$summary))) {
        s <- obj$summary[i,]
        center <- mean(c(abs(s$minimum), abs(s$maximum)), na.rm=TRUE)
        rel <- if (is.finite(center) && center > 0) s$sd/center else s$sd
        status <- if (!is.finite(rel)) "review" else if (rel >= relative_sd_fail) "fail"
        else if (rel >= relative_sd_review) "review" else "pass"
        rows[[length(rows)+1L]] <- data.frame(dimension=nm, metric=s$metric,
                                             indicator=rel, status=status)
      }
    }
  }
  findings <- if (length(rows)) do.call(rbind, rows) else
    data.frame(dimension=character(), metric=character(), indicator=numeric(), status=character())
  structure(
    list(status=if (!nrow(findings)) "review" else .gp3ml_ng_status(findings$status),
         findings=findings,
         note="Robustness statuses summarize sensitivity diagnostics; they are not proof of model validity."),
    class="gp3ml_model_robustness_audit"
  )
}

#' Plot a robustness audit
#' @param x A `gp3ml_model_robustness_audit`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_model_robustness_audit
#' @export
plot.gp3ml_model_robustness_audit <- function(x, ...) {
  if (!nrow(x$findings)) .gp3ml_ng_stop("No robustness findings are available.")
  vals <- x$findings$indicator
  names(vals) <- paste(x$findings$dimension, x$findings$metric, sep=": ")
  graphics::barplot(vals, horiz=TRUE, las=1, xlab="Sensitivity indicator",
                    main="Model robustness and stability", ...)
  invisible(x)
}
