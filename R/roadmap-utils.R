.gp3ml_capture_conditions <- function(expr) {
  warnings <- character()
  messages <- character()
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) structure(
      list(message = conditionMessage(e), call = conditionCall(e)),
      class = "gp3ml_captured_error"
    )
  )
  list(
    value = value,
    error = if (inherits(value, "gp3ml_captured_error")) value$message else NA_character_,
    warnings = unique(warnings),
    messages = unique(messages)
  )
}

.gp3ml_metric_long <- function(metrics, identifiers = list()) {
  if (!is.data.frame(metrics) || nrow(metrics) != 1L) return(data.frame())
  numeric_names <- names(metrics)[vapply(metrics, is.numeric, logical(1))]
  numeric_names <- setdiff(numeric_names, c("n", "threshold"))
  if (!length(numeric_names)) return(data.frame())
  if (length(identifiers)) {
    base <- as.data.frame(
      identifiers,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    if (nrow(base) != 1L) .gp3ml_stop("Metric identifiers must define one row.")
    base <- base[rep(1L, length(numeric_names)), , drop = FALSE]
  } else {
    base <- data.frame(.gp3ml_row = seq_along(numeric_names))
  }
  base$metric <- numeric_names
  base$value <- vapply(numeric_names, function(name) as.numeric(metrics[[name]][[1L]]), numeric(1))
  base$n <- if ("n" %in% names(metrics)) as.integer(metrics$n[[1L]]) else NA_integer_
  base$threshold <- if ("threshold" %in% names(metrics)) as.numeric(metrics$threshold[[1L]]) else NA_real_
  base$.gp3ml_row <- NULL
  rownames(base) <- NULL
  base
}

.gp3ml_predictions_from_model <- function(model, data, task, threshold) {
  if (task$task_type == "classification") {
    probability <- as.numeric(stats::predict(model, data, type = "probability"))
    prediction <- stats::predict(model, data, type = "class")
    list(prediction = prediction, probability = probability)
  } else {
    prediction <- as.numeric(stats::predict(model, data, type = "response"))
    list(prediction = prediction, probability = NULL)
  }
}

.gp3ml_prediction_table <- function(
    data,
    task,
    fold_object,
    predictions,
    source_row_id,
    candidate_id = NA_character_,
    stage = "assessment") {
  ids <- unique(c(
    source_row_id,
    task$unit_id,
    task$participant_id,
    task$stimulus_id
  ))
  ids <- ids[!is.na(ids) & nzchar(ids) & ids %in% names(data)]
  out <- data[ids, drop = FALSE]
  out[["repeat"]] <- fold_object[["repeat"]]
  out$fold <- fold_object$fold
  out$fold_id <- fold_object$fold_id
  out$candidate_id <- candidate_id
  out$stage <- stage
  out$truth <- as.character(data[[task$outcome]])
  out$prediction <- as.character(predictions$prediction)
  out$probability <- if (is.null(predictions$probability)) NA_real_ else as.numeric(predictions$probability)
  out$prediction_missing <- is.na(out$prediction) & is.na(out$probability)
  out
}

.gp3ml_seed_from <- function(seed, ...) {
  values <- unlist(list(...), recursive = TRUE, use.names = FALSE)
  token <- paste(c(as.integer(seed), values), collapse = "|")
  raw <- utf8ToInt(token)
  as.integer((sum(raw * seq_along(raw)) %% (.Machine$integer.max - 1L)) + 1L)
}

.gp3ml_list_column <- function(x) {
  I(unname(x))
}

.gp3ml_quantile_interval <- function(x, conf_level = 0.95) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (!length(x)) return(c(lower = NA_real_, upper = NA_real_))
  alpha <- (1 - conf_level) / 2
  stats::quantile(x, c(alpha, 1 - alpha), na.rm = TRUE, names = FALSE)
}


.gp3ml_roadmap_metric_direction <- function(metric) {
  if (metric %in% c(
    "rmse", "mae", "log_loss", "brier", "ece",
    "calibration_intercept_abs", "calibration_slope_abs_error"
  )) "minimize" else "maximize"
}

.gp3ml_validate_direction <- function(metric, direction) {
  direction <- match.arg(direction, c("maximize", "minimize"))
  if (identical(metric, "accuracy")) {
    .gp3ml_stop(
      "`accuracy` cannot be the primary governed selection metric. Use a discrimination, calibration, or error metric and report accuracy only as a secondary measure."
    )
  }
  direction
}

.gp3ml_status_rank <- function(status) {
  match(status, c("pass", "review", "fail"), nomatch = 3L)
}

.gp3ml_worst_status <- function(status) {
  if (!length(status)) return("fail")
  c("pass", "review", "fail")[[max(.gp3ml_status_rank(status), na.rm = TRUE)]]
}
