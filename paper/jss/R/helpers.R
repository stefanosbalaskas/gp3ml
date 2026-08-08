# Helper functions for the gp3ml R Journal manuscript.
# These functions are manuscript infrastructure, not gp3ml package APIs.

`%||%` <- function(x, y) if (is.null(x)) y else x

locate_gp3ml_root <- function(start = getwd()) {
  starts <- unique(c(start, dirname(start), dirname(dirname(start))))
  starts <- normalizePath(starts, winslash = "/", mustWork = FALSE)
  for (candidate in starts) {
    description <- file.path(candidate, "DESCRIPTION")
    if (file.exists(description)) {
      dcf <- tryCatch(read.dcf(description), error = function(e) NULL)
      if (!is.null(dcf) && identical(unname(dcf[1L, "Package"]), "gp3ml")) {
        return(candidate)
      }
    }
  }
  stop("Could not locate the gp3ml repository root from: ", start, call. = FALSE)
}

assert_namespace <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Package `", package, "` is required to render this manuscript.", call. = FALSE)
  }
  invisible(TRUE)
}

compact_number <- function(x, digits = 3L) {
  ifelse(is.na(x), "NA", formatC(x, digits = digits, format = "fg", flag = "#"))
}

safe_kable <- function(x, caption = NULL, digits = 3L, ...) {
  knitr::kable(x, caption = caption, digits = digits, booktabs = TRUE, ...)
}

package_audit <- function(repo_root) {
  desc <- read.dcf(file.path(repo_root, "DESCRIPTION"))
  namespace_lines <- readLines(file.path(repo_root, "NAMESPACE"), warn = FALSE)
  exported <- unique(sub('^export\\(([^)]+)\\).*$', '\\1', grep('^export\\(', namespace_lines, value = TRUE)))
  exported <- gsub('^"|"$', '', exported)
  contracts <- gp3ml::gp3ml_api_contracts()
  audit <- gp3ml::audit_gp3ml_api_stability(contracts)
  engines <- gp3ml::gp3ml_engine_capabilities()
  suggests_raw <- unname(desc[1L, "Suggests"])
  suggests <- if (is.na(suggests_raw) || !nzchar(suggests_raw)) {
    character()
  } else {
    trimws(gsub("\\s*\\([^)]*\\)", "", strsplit(suggests_raw, ",", fixed = TRUE)[[1L]]))
  }
  suggests <- suggests[nzchar(suggests)]
  list(
    package = unname(desc[1L, "Package"]),
    version = unname(desc[1L, "Version"]),
    title = unname(desc[1L, "Title"]),
    license = unname(desc[1L, "License"]),
    exports_from_namespace = length(exported),
    stable_exports = sum(contracts$exports$stability == "stable"),
    experimental_exports = sum(contracts$exports$stability == "experimental"),
    stable_classes = nrow(contracts$classes),
    api_audit_status = audit$status,
    api_differences = nrow(audit$differences),
    source_vignettes = length(list.files(file.path(repo_root, "vignettes"), pattern = "\\.[Rr]md$")),
    rd_topics = length(list.files(file.path(repo_root, "man"), pattern = "\\.Rd$")),
    optional_dependencies = sort(suggests),
    engines = engines,
    contracts = contracts,
    audit = audit
  )
}

binary_metrics <- function(truth, probability, positive, threshold = 0.5) {
  truth <- as.character(truth)
  keep <- !is.na(truth) & !is.na(probability)
  truth <- truth[keep]
  probability <- pmin(pmax(as.numeric(probability[keep]), 1e-15), 1 - 1e-15)
  negative <- setdiff(sort(unique(truth)), positive)
  if (length(negative) != 1L) stop("Binary outcome required.", call. = FALSE)
  prediction <- ifelse(probability >= threshold, positive, negative)
  tp <- sum(prediction == positive & truth == positive)
  tn <- sum(prediction == negative & truth == negative)
  fp <- sum(prediction == positive & truth == negative)
  fn <- sum(prediction == negative & truth == positive)
  sensitivity <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_
  specificity <- if ((tn + fp) > 0) tn / (tn + fp) else NA_real_
  precision <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
  recall <- sensitivity
  f1 <- if (is.finite(precision) && is.finite(recall) && (precision + recall) > 0) {
    2 * precision * recall / (precision + recall)
  } else NA_real_
  y <- as.integer(truth == positive)
  ranks <- rank(probability, ties.method = "average")
  n_pos <- sum(y == 1L)
  n_neg <- sum(y == 0L)
  roc_auc <- if (n_pos > 0L && n_neg > 0L) {
    (sum(ranks[y == 1L]) - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
  } else NA_real_
  data.frame(
    metric = c("accuracy", "balanced_accuracy", "sensitivity", "specificity", "precision", "recall", "f1", "roc_auc", "brier", "log_loss"),
    value = c(
      mean(prediction == truth),
      mean(c(sensitivity, specificity), na.rm = TRUE),
      sensitivity, specificity, precision, recall, f1, roc_auc,
      mean((probability - y)^2),
      -mean(y * log(probability) + (1 - y) * log(1 - probability))
    ),
    stringsAsFactors = FALSE
  )
}

naive_row_cv_glm <- function(data, outcome, predictors, positive, v = 5L, repeats = 2L, seed = 1L) {
  set.seed(seed)
  n <- nrow(data)
  rows <- vector("list", v * repeats)
  position <- 1L
  for (r in seq_len(repeats)) {
    fold_id <- sample(rep(seq_len(v), length.out = n))
    for (f in seq_len(v)) {
      analysis <- data[fold_id != f, , drop = FALSE]
      assessment <- data[fold_id == f, , drop = FALSE]
      # The comparator is intentionally row-wise and therefore allows the same
      # participant and stimulus to appear in analysis and assessment.
      medians <- vapply(analysis[predictors], function(z) stats::median(z, na.rm = TRUE), numeric(1))
      for (nm in predictors) {
        analysis[[nm]][is.na(analysis[[nm]])] <- medians[[nm]]
        assessment[[nm]][is.na(assessment[[nm]])] <- medians[[nm]]
      }
      formula <- stats::reformulate(predictors, response = outcome)
      fit <- stats::glm(formula, data = analysis, family = stats::binomial())
      probability <- as.numeric(stats::predict(fit, newdata = assessment, type = "response"))
      metrics <- binary_metrics(assessment[[outcome]], probability, positive)
      metrics[["repeat"]] <- r
      metrics$fold <- f
      metrics$design <- "Naive row-level"
      rows[[position]] <- list(
        metrics = metrics,
        predictions = data.frame(
          `repeat` = r,
          fold = f,
          participant_id = assessment$participant_id,
          stimulus_id = assessment$stimulus_id,
          truth = assessment[[outcome]],
          probability = probability,
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
      )
      position <- position + 1L
    }
  }
  list(
    metrics = do.call(rbind, lapply(rows, `[[`, "metrics")),
    predictions = do.call(rbind, lapply(rows, `[[`, "predictions"))
  )
}

metric_distribution <- function(metrics, design) {
  metrics$design <- design
  metrics[, c("design", "repeat", "fold", "metric", "value"), drop = FALSE]
}

summarise_metric_distribution <- function(x, conf_level = 0.95) {
  split_rows <- split(x, interaction(x$design, x$metric, drop = TRUE))
  alpha <- (1 - conf_level) / 2
  out <- lapply(split_rows, function(z) {
    values <- z$value[is.finite(z$value)]
    data.frame(
      design = z$design[[1L]],
      metric = z$metric[[1L]],
      n_folds = length(values),
      mean = if (length(values)) mean(values) else NA_real_,
      sd = if (length(values) > 1L) stats::sd(values) else NA_real_,
      lower = if (length(values)) unname(stats::quantile(values, alpha, na.rm = TRUE)) else NA_real_,
      upper = if (length(values)) unname(stats::quantile(values, 1 - alpha, na.rm = TRUE)) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, out)
  row.names(result) <- NULL
  result
}

plot_architecture <- function() {
  old <- par(mar = c(1.2, 1.2, 2.2, 1.2), xpd = NA)
  on.exit(par(old), add = TRUE)
  plot.new()
  plot.window(xlim = c(0, 3.2), ylim = c(0, 2.7))
  labels <- c("Declare", "Partition", "Prepare and fit", "Evaluate", "Decide", "Preserve")
  details <- c("purpose and roles", "target-aligned folds", "fold-local operations", "uncertainty and shift", "thresholds and abstention", "artefacts and contracts")
  x <- c(0.55, 1.60, 2.65, 2.65, 1.60, 0.55)
  y <- c(1.85, 1.85, 1.85, 0.85, 0.85, 0.85)
  for (i in seq_along(labels)) {
    rect(x[i] - 0.42, y[i] - 0.28, x[i] + 0.42, y[i] + 0.28, border = "black", lwd = 1.1)
    text(x[i], y[i] + 0.06, labels[i], font = 2, cex = 0.86)
    text(x[i], y[i] - 0.10, details[i], cex = 0.62)
  }
  arrows(x[1] + 0.44, y[1], x[2] - 0.44, y[2], length = 0.07, lwd = 1)
  arrows(x[2] + 0.44, y[2], x[3] - 0.44, y[3], length = 0.07, lwd = 1)
  arrows(x[3], y[3] - 0.30, x[4], y[4] + 0.30, length = 0.07, lwd = 1)
  arrows(x[4] - 0.44, y[4], x[5] + 0.44, y[5], length = 0.07, lwd = 1)
  arrows(x[5] - 0.44, y[5], x[6] + 0.44, y[6], length = 0.07, lwd = 1)
  rect(0.12, 2.36, 3.08, 2.62, border = "black", lty = 2)
  text(1.60, 2.49, "Scientific scope, permitted outcomes and prohibited uses", cex = 0.72)
  rect(0.12, 0.08, 3.08, 0.34, border = "black", lty = 2)
  text(1.60, 0.21, "Provenance, audit trails, API stability and release evidence", cex = 0.72)
  title("Governance-first package architecture")
}


plot_resampling_schemes <- function(data, group_folds, crossed_folds) {
  old <- par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
  on.exit(par(old), add = TRUE)
  set.seed(20260807)
  n_show <- min(120L, nrow(data))
  idx <- sample(seq_len(nrow(data)), n_show)
  row_fold <- sample(rep(seq_len(5L), length.out = n_show))
  barplot(
    rep(1, n_show),
    col = row_fold,
    border = NA,
    axes = FALSE,
    space = 0.08,
    main = "Row-level split"
  )
  mtext("Rows from the same clusters may cross partitions", side = 1, line = 2, cex = 0.72)
  first_group <- group_folds$folds[[1L]]
  p <- sort(unique(c(as.character(first_group$analysis$participant_id), as.character(first_group$assessment$participant_id))))
  status <- ifelse(p %in% first_group$assessment$participant_id, 2, 1)
  barplot(rep(1, length(p)), col = status, border = NA, axes = FALSE, main = "Participant grouped")
  mtext("Participants are assigned wholly to one side", side = 1, line = 2, cex = 0.72)
  first_cross <- crossed_folds$folds[[1L]]
  participants <- sort(unique(data$participant_id))
  stimuli <- sort(unique(data$stimulus_id))
  mat <- matrix(0, nrow = length(participants), ncol = length(stimuli), dimnames = list(participants, stimuli))
  a <- unique(first_cross$analysis[c("participant_id", "stimulus_id")]); mat[cbind(match(a$participant_id, participants), match(a$stimulus_id, stimuli))] <- 1
  z <- unique(first_cross$assessment[c("participant_id", "stimulus_id")]); mat[cbind(match(z$participant_id, participants), match(z$stimulus_id, stimuli))] <- 2
  e <- unique(first_cross$excluded[c("participant_id", "stimulus_id")]); if (nrow(e)) mat[cbind(match(e$participant_id, participants), match(e$stimulus_id, stimuli))] <- 3
  image(t(mat[nrow(mat):1, , drop = FALSE]), axes = FALSE, main = "Participant–stimulus blocks")
  mtext("Cross-block rows are retained as excluded", side = 1, line = 2, cex = 0.72)
}

plot_validation_profile <- function(metrics, summary_table) {
  metrics_to_show <- c("roc_auc", "balanced_accuracy", "brier", "log_loss")
  titles <- c(roc_auc = "ROC AUC", balanced_accuracy = "Balanced accuracy", brier = "Brier score", log_loss = "Log loss")
  designs <- c("Naive row-level", "Participant grouped", "Participant-stimulus blocks")
  short_names <- c("Rows", "Participants", "Crossed")
  old <- par(mfrow = c(2, 2), mar = c(4.2, 4.0, 2.4, 0.8))

  # R Journal figure-width refinement
  par(
    mar = c(5.8, 4.3, 2.5, 1.0),
    oma = c(0.2, 0.2, 0.2, 0.2),
    mgp = c(2.5, 0.75, 0),
    tcl = -0.3,
    cex.axis = 0.84,
    cex.lab = 0.92,
    cex.main = 0.98
  )
  on.exit(par(old), add = TRUE)
  for (metric in metrics_to_show) {
    raw <- metrics[metrics$metric == metric, , drop = FALSE]
    sm <- summary_table[summary_table$metric == metric, , drop = FALSE]
    sm <- sm[match(designs, sm$design), , drop = FALSE]
    finite_values <- raw$value[is.finite(raw$value)]
    finite_limits <- c(finite_values, sm$lower, sm$upper)
    finite_limits <- finite_limits[is.finite(finite_limits)]
    pad <- if (length(finite_limits)) max(diff(range(finite_limits)) * 0.18, 0.02) else 0.05
    ylim <- if (length(finite_limits)) range(finite_limits) + c(-pad, pad) else c(0, 1)
    if (metric %in% c("roc_auc", "balanced_accuracy")) ylim <- range(c(0.45, ylim))
    plot(NA, xlim = c(0.6, 3.4), ylim = ylim, xaxt = "n", xlab = "", ylab = titles[[metric]], main = titles[[metric]])
    axis(1, at = 1:3, labels = short_names, las = 2, cex.axis = 0.78)
    for (i in seq_along(designs)) {
      z <- raw[raw$design == designs[[i]], , drop = FALSE]
      if (nrow(z)) {
        jitter_x <- i + seq(-0.11, 0.11, length.out = nrow(z))
        points(jitter_x, z$value, pch = 1, cex = 0.62)
      }
      if (nrow(sm) >= i && is.finite(sm$mean[[i]])) {
        segments(i, sm$lower[[i]], i, sm$upper[[i]], lwd = 2)
        segments(i - 0.07, sm$lower[[i]], i + 0.07, sm$lower[[i]], lwd = 2)
        segments(i - 0.07, sm$upper[[i]], i + 0.07, sm$upper[[i]], lwd = 2)
        points(i, sm$mean[[i]], pch = 18, cex = 1.15)
      }
    }
    if (metric %in% c("roc_auc", "balanced_accuracy")) abline(h = 0.5, lty = 2)
  }
}


plot_calibration_conformal <- function(calibration, conformal_coverage, conformal_set_size) {
  old <- par(mfrow = c(1, 2), mar = c(4.2, 4.1, 2.6, 0.8))
  on.exit(par(old), add = TRUE)
  tab <- calibration$reliability
  plot(tab$mean_probability, tab$observed_rate, xlim = c(0, 1), ylim = c(0, 1), xlab = "Mean predicted probability", ylab = "Observed review rate", pch = 19, cex = sqrt(tab$n / max(tab$n)) * 1.5 + 0.4, main = "Calibration")
  abline(0, 1, lty = 2)
  coverage <- c(Nominal = conformal_coverage$nominal_coverage, Rows = conformal_coverage$row_coverage, Participants = conformal_coverage$unit_coverage)
  barplot(coverage, ylim = c(0, 1.05), ylab = "Coverage", main = "Held-out conformal coverage")
  abline(h = conformal_coverage$nominal_coverage, lty = 2)
  mtext(sprintf("Mean set size: %.2f classes", mean(conformal_set_size)), side = 1, line = 3.0, cex = 0.76)
}


compute_abstention_frontier <- function(truth, probability, positive, threshold, widths = seq(0, 0.20, by = 0.025)) {
  truth <- as.character(truth)
  negative <- setdiff(sort(unique(truth)), positive)
  stopifnot(length(negative) == 1L)
  rows <- lapply(widths, function(width) {
    lower <- max(0, threshold - width)
    upper <- min(1, threshold + width)
    abstain <- probability >= lower & probability <= upper
    prediction <- ifelse(probability >= threshold, positive, negative)
    covered <- !abstain
    data.frame(
      half_width = width,
      coverage = mean(covered),
      covered_error = if (any(covered)) mean(prediction[covered] != truth[covered]) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

plot_threshold_and_abstention <- function(threshold_evaluation, rule, policy_predictions, positive, abstention_audit) {
  old <- par(mfrow = c(1, 2), mar = c(4.2, 4.1, 2.6, 0.8))
  on.exit(par(old), add = TRUE)
  tab <- threshold_evaluation$thresholds
  plot(tab$threshold, tab$balanced_accuracy, type = "b", xlab = "Probability threshold", ylab = "Balanced accuracy", main = "Threshold development")
  abline(v = rule$threshold, lty = 2)
  frontier <- compute_abstention_frontier(policy_predictions$truth, policy_predictions$probability, positive, rule$threshold)
  plot(frontier$coverage, frontier$covered_error, type = "b", xlim = rev(range(frontier$coverage, na.rm = TRUE)), xlab = "Retained coverage", ylab = "Error among retained cases", main = "Abstention sensitivity")
  points(abstention_audit$coverage, abstention_audit$covered_error_rate, pch = 18, cex = 1.3)
  text(abstention_audit$coverage, abstention_audit$covered_error_rate, labels = " declared policy", pos = 4, cex = 0.68)
}


plot_shift <- function(shift) {
  tab <- shift$findings
  magnitude <- ifelse(tab$type == "numeric", abs(tab$standardized_difference), tab$distribution_statistic)
  ord <- order(magnitude)
  magnitude <- magnitude[ord]
  labels <- paste0(tab$predictor[ord], " (", tab$status[ord], ")")
  bp <- barplot(magnitude, names.arg = labels, horiz = TRUE, las = 1, xlab = "Absolute standardized difference or total variation", main = "Predictor distribution shift")
  abline(v = 0.2, lty = 3)
  invisible(bp)
}


write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  normalizePath(path, winslash = "/", mustWork = TRUE)
}



# >>> R JOURNAL WIDTH SAFETY START >>>

safe_kable <- function(x, caption = NULL, digits = 3L, ...) {

  html_output <- isTRUE(knitr::is_html_output())

  if (html_output) {

    tab <- knitr::kable(
      x,
      format = "html",
      caption = caption,
      digits = digits,
      ...
    )

    tab <- kableExtra::kable_styling(
      tab,
      full_width = TRUE,
      position = "center"
    )

    return(
      knitr::asis_output(
        as.character(tab)
      )
    )
  }

  tab <- knitr::kable(
    x,
    format = "latex",
    caption = caption,
    digits = digits,
    booktabs = TRUE,
    longtable = FALSE,
    ...
  )

  tab <- kableExtra::kable_styling(
    tab,
    latex_options = "scale_down",
    full_width = FALSE,
    position = "center"
  )

  knitr::asis_output(
    as.character(tab)
  )
}

## Compact resampling figure for the journal text block.
plot_resampling_schemes <- function(data, group_folds, crossed_folds) {

  old <- par(
    mfrow = c(1, 3),
    mar = c(0.4, 0.3, 1.55, 0.3),
    oma = c(0, 0, 0, 0),
    cex.main = 0.68,
    xpd = FALSE
  )

  on.exit(
    par(old),
    add = TRUE
  )

  set.seed(20260807)

  n_show <- min(90L, nrow(data))

  row_fold <- sample(
    rep(
      seq_len(5L),
      length.out = n_show
    )
  )

  barplot(
    rep(1, n_show),
    col = row_fold,
    border = NA,
    axes = FALSE,
    space = 0.02,
    main = "Rows"
  )

  box()

  first_group <- group_folds$folds[[1L]]

  participants <- sort(
    unique(
      c(
        as.character(first_group$analysis$participant_id),
        as.character(first_group$assessment$participant_id)
      )
    )
  )

  participant_status <- ifelse(
    participants %in% first_group$assessment$participant_id,
    2,
    1
  )

  barplot(
    rep(1, length(participants)),
    col = participant_status,
    border = NA,
    axes = FALSE,
    space = 0.02,
    main = "Participants"
  )

  box()

  first_cross <- crossed_folds$folds[[1L]]

  participant_levels <- sort(
    unique(data$participant_id)
  )

  stimulus_levels <- sort(
    unique(data$stimulus_id)
  )

  mat <- matrix(
    0,
    nrow = length(participant_levels),
    ncol = length(stimulus_levels)
  )

  analysis_cells <- unique(
    first_cross$analysis[
      c("participant_id", "stimulus_id")
    ]
  )

  mat[cbind(
    match(
      analysis_cells$participant_id,
      participant_levels
    ),
    match(
      analysis_cells$stimulus_id,
      stimulus_levels
    )
  )] <- 1

  assessment_cells <- unique(
    first_cross$assessment[
      c("participant_id", "stimulus_id")
    ]
  )

  mat[cbind(
    match(
      assessment_cells$participant_id,
      participant_levels
    ),
    match(
      assessment_cells$stimulus_id,
      stimulus_levels
    )
  )] <- 2

  excluded_cells <- unique(
    first_cross$excluded[
      c("participant_id", "stimulus_id")
    ]
  )

  if (nrow(excluded_cells)) {

    mat[cbind(
      match(
        excluded_cells$participant_id,
        participant_levels
      ),
      match(
        excluded_cells$stimulus_id,
        stimulus_levels
      )
    )] <- 3
  }

  image(
    t(
      mat[
        nrow(mat):1,
        ,
        drop = FALSE
      ]
    ),
    axes = FALSE,
    main = "Crossed"
  )

  box()
}

# <<< R JOURNAL WIDTH SAFETY END <<<
