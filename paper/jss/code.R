#' # Replication script for the gp3ml JSS manuscript
#'
#' This script reproduces the figures and principal result tables used in
#' "gp3ml: Governance-First Predictive Modelling and Validation for Gazepoint
#' Research in R". It assumes gp3ml 0.3.0 has been installed from the submitted
#' package source. No private participant data are used.
#'
#' The analysis uses deterministic synthetic data and fixed seeds.

jss_dir <- Sys.getenv("GP3ML_JSS_DIR", unset = "")
if (!nzchar(jss_dir)) {
  jss_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)
} else {
  jss_dir <- normalizePath(jss_dir, winslash = "/", mustWork = TRUE)
}
setwd(jss_dir)

# Compatibility context required by the frozen case-study source.
# For the JSS track, manuscript outputs remain inside paper/jss/.
paper_dir <- jss_dir
repo_root <- normalizePath(
  file.path(jss_dir, "..", ".."),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(
  requireNamespace("gp3ml", quietly = TRUE),
  as.character(utils::packageVersion("gp3ml")) == "0.3.0"
)

library(gp3ml)

source(file.path("R", "helpers.R"), local = TRUE)
case_output_dir <- tempfile("gp3ml-jss-case-output-")
dir.create(
  case_output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)
paper_dir <- case_output_dir
source(file.path("R", "case-study.R"), local = TRUE)
unlink(
  case_output_dir,
  recursive = TRUE,
  force = TRUE
)
paper_dir <- jss_dir

dir.create("figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output", recursive = TRUE, showWarnings = FALSE)

save_pdf <- function(path, expr, width = 7.0, height = 4.8) {
  grDevices::pdf(path, width = width, height = height, useDingbats = FALSE)
  on.exit(grDevices::dev.off(), add = TRUE)
  result <- force(expr)
  if (inherits(result, "ggplot")) print(result)
  grDevices::dev.off()
  on.exit(NULL, add = FALSE)
  info <- pdftools::pdf_info(path)
  if (info$pages < 1L) {
    stop("Generated figure has no PDF pages: ", path, call. = FALSE)
  }
  invisible(path)
}

#' ## Figure 1: package architecture
save_pdf(
  file.path("figures", "architecture-figure-1.pdf"),
  plot_architecture(),
  width = 6.8, height = 5.1
)

#' ## Figure 2: validation designs
save_pdf(
  file.path("figures", "resampling-design-figure-1.pdf"),
  plot_resampling_schemes(analysis_data, group_folds, cross_folds),
  width = 7.2, height = 4.4
)

#' ## Figure 3: balanced accuracy by validation design
save_pdf(
  file.path("figures", "performance-comparison-figure-1.pdf"),
  {
    z <- performance_summary[
      performance_summary$metric == "balanced_accuracy",
      ,
      drop = FALSE
    ]
    desired <- c(
      "Naive row-level",
      "Participant grouped",
      "Participant-stimulus blocks"
    )
    z <- z[match(desired, z$design), , drop = FALSE]
    stopifnot(
      nrow(z) == 3L,
      all(z$design == desired),
      all(is.finite(z$mean))
    )
    bp <- barplot(
      z$mean,
      names.arg = c("Rows", "Participants", "Crossed blocks"),
      las = 2,
      ylim = c(0, max(1, z$upper, na.rm = TRUE)),
      ylab = "Balanced accuracy",
      main = "Validation design changes the estimand"
    )
    bp <- as.numeric(bp)
    interval_ok <- is.finite(z$lower) & is.finite(z$upper)
    if (any(interval_ok)) {
      segments(
        bp[interval_ok], z$lower[interval_ok],
        bp[interval_ok], z$upper[interval_ok]
      )
      cap <- 0.08
      segments(
        bp[interval_ok] - cap, z$lower[interval_ok],
        bp[interval_ok] + cap, z$lower[interval_ok]
      )
      segments(
        bp[interval_ok] - cap, z$upper[interval_ok],
        bp[interval_ok] + cap, z$upper[interval_ok]
      )
    }
    abline(h = 0.5, lty = 2)
  },
  width = 6.8, height = 4.5
)

#' ## Figure 4: calibration
save_pdf(
  file.path("figures", "calibration-figure-1.pdf"),
  {
    tab <- calibration$reliability
    required <- c(
      "mean_probability",
      "observed_rate",
      "n"
    )
    stopifnot(
      is.data.frame(tab),
      all(required %in% names(tab)),
      nrow(tab) > 0L,
      any(is.finite(tab$mean_probability)),
      any(is.finite(tab$observed_rate))
    )
    size <- sqrt(tab$n / max(tab$n, na.rm = TRUE)) * 1.5 + 0.4
    plot(
      tab$mean_probability,
      tab$observed_rate,
      xlim = c(0, 1),
      ylim = c(0, 1),
      xlab = "Mean predicted probability",
      ylab = "Observed review rate",
      pch = 19,
      cex = size,
      main = "Participant-grouped calibration"
    )
    abline(
      0,
      1,
      lty = 2
    )
  },
  width = 6.6, height = 4.5
)

#' ## Figure 5: threshold and abstention
save_pdf(
  file.path("figures", "threshold-abstention-figure-1.pdf"),
  plot_threshold_and_abstention(
    threshold_evaluation,
    decision_rule,
    policy_audit_predictions,
    quality_task$positive,
    abstention_audit
  ),
  width = 7.2, height = 4.5
)

#' ## Figure 6: predictor shift
save_pdf(
  file.path("figures", "shift-figure-1.pdf"),
  plot_shift(shift_audit),
  width = 6.8, height = 4.3
)

#' ## Principal result tables
show_metrics <- c("balanced_accuracy", "roc_auc", "brier", "log_loss")
performance_export <- performance_summary[
  performance_summary$metric %in% show_metrics,
  ,
  drop = FALSE
]

utils::write.csv(
  performance_export,
  file.path("output", "performance-summary.csv"),
  row.names = FALSE
)

utils::write.csv(
  calibration$summary,
  file.path("output", "calibration-summary.csv"),
  row.names = FALSE
)

conformal_export <- data.frame(
  nominal_coverage = conformal_coverage$nominal_coverage,
  held_out_row_coverage = conformal_coverage$row_coverage,
  held_out_participant_all_rows_coverage = conformal_coverage$unit_coverage,
  mean_set_size = mean(conformal_set_size),
  calibration_units = conformal_fit$n_calibration_units,
  audit_units = length(unique(policy_audit_predictions$participant_id)),
  status = conformal_coverage$status
)

utils::write.csv(
  conformal_export,
  file.path("output", "conformal-summary.csv"),
  row.names = FALSE
)

utils::write.csv(
  shift_audit$findings,
  file.path("output", "shift-findings.csv"),
  row.names = FALSE
)

governance_export <- data.frame(
  evidence = c(
    "analysis_plan_validation",
    "group_fold_audit",
    "decision_rule_validation",
    "model_artifact_validation",
    "environment_comparison",
    "api_stability"
  ),
  status = c(
    analysis_plan_validation$status,
    group_audit$status,
    decision_validation$status,
    artifact_validation$status,
    environment_comparison$status,
    api_stability$status
  )
)

utils::write.csv(
  governance_export,
  file.path("output", "governance-validation.csv"),
  row.names = FALSE
)

#' ## Reproducibility assertions
stopifnot(
  nrow(analysis_data) == 480L,
  length(unique(analysis_data$participant_id)) == 30L,
  length(unique(analysis_data$stimulus_id)) == 8L,
  group_audit$status == "pass",
  cross_audit$status == "pass",
  analysis_plan_validation$status == "pass",
  decision_validation$status == "pass",
  artifact_validation$status == "pass",
  environment_comparison$status == "pass",
  api_stability$status == "pass",
  abs(conformal_coverage$nominal_coverage - 0.9) < 1e-12,
  abs(conformal_coverage$row_coverage - 1) < 1e-12,
  abs(conformal_coverage$unit_coverage - 1) < 1e-12
)

#' ## Session information
utils::sessionInfo()
