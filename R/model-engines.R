.gp3ml_default_predictors <- function(data, task) {
  setdiff(names(data), c(task$outcome, task$unit_id, task$participant_id, task$stimulus_id))
}

.gp3ml_training_summary <- function(data, predictors) {
  summaries <- lapply(predictors, function(name) {
    x <- data[[name]]
    if (is.numeric(x)) {
      list(type = "numeric", mean = mean(x, na.rm = TRUE), sd = stats::sd(x, na.rm = TRUE), missing = sum(is.na(x)))
    } else {
      list(type = "categorical", levels = sort(unique(as.character(x[!is.na(x)]))), missing = sum(is.na(x)))
    }
  })
  names(summaries) <- predictors
  summaries
}

#' List available model engines
#'
#' @examples
#' gp3ml_available_engines()
#' @return A data frame listing supported model-engine names and whether each optional engine is currently available.
#' @export
gp3ml_available_engines <- function() {
  data.frame(
    engine = c("glm", "lm", "ranger", "xgboost", "nnet", "keras3", "custom"),
    available = c(TRUE, TRUE, requireNamespace("ranger", quietly = TRUE), requireNamespace("xgboost", quietly = TRUE), requireNamespace("nnet", quietly = TRUE), requireNamespace("keras3", quietly = TRUE), TRUE),
    stringsAsFactors = FALSE
  )
}

#' Integrate a controlled black-box model engine
#'
#' @param name Unique name for the custom engine.
#' @param fit_fun Function that fits the custom engine.
#' @param predict_fun Function that generates predictions.
#' @param supports Task types supported by the engine.
#' @param probability Whether classification probabilities are supported.
#' @param metadata Optional engine metadata.
#' @param safety_declaration Named logical safety declarations.
#'
#' @examples
#' custom_fit <- function(x, y, task, args) {
#'   training_data <- data.frame(
#'     .outcome = y,
#'     x,
#'     check.names = FALSE
#'   )
#'   stats::glm(
#'     .outcome ~ .,
#'     data = training_data,
#'     family = stats::binomial()
#'   )
#' }
#' custom_predict <- function(fit, newdata, type, task, ...) {
#'   as.numeric(stats::predict(
#'     fit,
#'     newdata = as.data.frame(newdata),
#'     type = "response"
#'   ))
#' }
#' engine <- integrate_black_box_model(
#'   name = "custom_glm",
#'   fit_fun = custom_fit,
#'   predict_fun = custom_predict,
#'   supports = "classification",
#'   probability = TRUE,
#'   safety_declaration = list(
#'     prohibited_uses_acknowledged = TRUE,
#'     prediction_time_inputs_only = TRUE,
#'     group_aware_evaluation_required = TRUE
#'   )
#' )
#' engine
#' @return A controlled `gp3ml_engine` object containing the custom fit and prediction functions, supported task types, metadata, and explicit safety declarations.
#' @export
integrate_black_box_model <- function(
    name,
    fit_fun,
    predict_fun,
    supports = c("classification", "regression"),
    probability = TRUE,
    metadata = list(),
    safety_declaration) {
  if (!is.function(fit_fun) || !is.function(predict_fun)) .gp3ml_stop("`fit_fun` and `predict_fun` must be functions.")
  required <- c("prohibited_uses_acknowledged", "prediction_time_inputs_only", "group_aware_evaluation_required")
  if (!is.list(safety_declaration) || !all(required %in% names(safety_declaration)) || !all(vapply(safety_declaration[required], isTRUE, logical(1)))) {
    .gp3ml_stop("Black-box integration requires explicit TRUE safety declarations for prohibited uses, prediction-time inputs, and group-aware evaluation.")
  }
  structure(
    list(name = name, fit_fun = fit_fun, predict_fun = predict_fun, supports = supports, probability = probability, metadata = metadata, safety_declaration = safety_declaration),
    class = "gp3ml_engine"
  )
}

#' Fit a governed Gazepoint model
#'
#' @param data Analysis data used to fit the model.
#' @param task A governed `gp3ml_task` object.
#' @param predictors Optional character vector of predictor columns.
#' @param engine Engine name or controlled custom-engine object.
#' @param preprocessor Optional fitted preprocessing object.
#' @param preprocessor_args Arguments passed to preprocessing fitting.
#' @param engine_args Arguments passed to the model engine.
#' @param seed Deterministic random seed.
#' @param threshold Classification probability threshold.
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
#' model <- fit_gazepoint_model(
#'   data = example_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' model
#' @return A governed `gp3ml_model` object containing the fitted engine, preprocessing object, task contract, predictors, and training metadata.
#' @export
fit_gazepoint_model <- function(
    data,
    task,
    predictors = NULL,
    engine = NULL,
    preprocessor = NULL,
    preprocessor_args = list(),
    engine_args = list(),
    seed = 1L,
    threshold = 0.5) {
  .gp3ml_assert_data(data)
  assert_gp3ml_use_case(task, data)
  predictors <- predictors %||% .gp3ml_default_predictors(data, task)
  .gp3ml_assert_columns(data, predictors, "predictors")
  forbidden <- intersect(predictors, c(task$outcome, task$unit_id, task$participant_id, task$stimulus_id))
  if (length(forbidden)) .gp3ml_stop("Outcome or identifiers cannot be predictors: %s.", paste(forbidden, collapse = ", "))
  custom_engine <- inherits(engine, "gp3ml_engine")
  if (is.null(engine)) engine <- if (task$task_type == "classification") "glm" else "lm"
  engine_name <- if (custom_engine) engine$name else as.character(engine[[1L]])
  if (!custom_engine && !engine_name %in% c("glm", "lm", "ranger", "xgboost", "nnet")) {
    .gp3ml_stop("Unknown engine `%s`. Use `fit_gazepoint_deep_model()` for keras3 or supply a gp3ml engine.", engine_name)
  }
  if (task$task_type == "classification" && engine_name == "lm") .gp3ml_stop("Use a classification engine.")
  if (task$task_type == "regression" && engine_name == "glm") engine_name <- "lm"
  restore <- .gp3ml_set_seed(seed)
  on.exit(restore(), add = TRUE)
  if (is.null(preprocessor)) {
    preprocessor <- do.call(fit_gazepoint_preprocessor, c(list(data = data, predictors = predictors), preprocessor_args))
  }
  x <- bake_gazepoint_preprocessor(preprocessor, data)
  if (!ncol(x)) .gp3ml_stop("No usable model columns remain after preprocessing.")
  if (task$task_type == "classification") {
    y <- as.integer(as.character(data[[task$outcome]]) == task$positive)
  } else y <- as.numeric(data[[task$outcome]])
  if (anyNA(y)) .gp3ml_stop("Training outcomes may not be missing.")
  fit <- NULL
  engine_spec <- NULL
  if (custom_engine) {
    if (!task$task_type %in% engine$supports) .gp3ml_stop("Custom engine does not support this task type.")
    fit <- engine$fit_fun(x = x, y = y, task = task, args = engine_args)
    engine_spec <- engine
  } else if (engine_name %in% c("glm", "lm")) {
    train <- data.frame(.outcome = y, x, check.names = FALSE)
    fit <- if (engine_name == "glm") stats::glm(.outcome ~ ., data = train, family = stats::binomial()) else stats::lm(.outcome ~ ., data = train)
  } else if (engine_name == "ranger") {
    if (!requireNamespace("ranger", quietly = TRUE)) .gp3ml_stop("Install `ranger` to use this engine.")
    args <- c(list(x = as.data.frame(x), y = if (task$task_type == "classification") factor(y, levels = c(0, 1)) else y, probability = task$task_type == "classification", seed = as.integer(seed)), engine_args)
    fit <- do.call(ranger::ranger, args)
  } else if (engine_name == "xgboost") {
    if (!requireNamespace("xgboost", quietly = TRUE)) .gp3ml_stop("Install `xgboost` to use this engine.")
    defaults <- list(data = x, label = y, objective = if (task$task_type == "classification") "binary:logistic" else "reg:squarederror", nrounds = 100L, verbose = 0L)
    fit <- do.call(xgboost::xgboost, .gp3ml_merge_lists(defaults, engine_args))
  } else if (engine_name == "nnet") {
    if (!requireNamespace("nnet", quietly = TRUE)) .gp3ml_stop("Install `nnet` to use this engine.")
    defaults <- list(x = x, y = y, size = 5L, linout = task$task_type == "regression", trace = FALSE, MaxNWts = 100000L)
    fit <- do.call(nnet::nnet, .gp3ml_merge_lists(defaults, engine_args))
  }
  structure(
    list(
      fit = fit,
      engine = engine_name,
      engine_spec = engine_spec,
      engine_args = engine_args,
      task = task,
      predictors = predictors,
      preprocessor = preprocessor,
      threshold = threshold,
      seed = seed,
      training_n = nrow(data),
      outcome_distribution = table(data[[task$outcome]], useNA = "ifany"),
      predictor_summary = .gp3ml_training_summary(data, predictors),
      training_hash = .gp3ml_hash_object(data[c(task$outcome, predictors)]),
      call = match.call()
    ),
    class = "gp3ml_model"
  )
}

#' Generic governed binary-classifier training wrapper
#'
#' @param data Analysis data used to train the classifier.
#' @param task A governed binary-classification task.
#' @param predictors Optional character vector of predictor columns.
#' @param engine Classification engine name or custom engine.
#' @param ... Additional arguments passed to `fit_gazepoint_model()`.
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
#' model <- train_gazepoint_classifier(
#'   data = example_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' model
#' @return A governed classification `gp3ml_model` object returned by `fit_gazepoint_model()`.
#' @export
train_gazepoint_classifier <- function(data, task, predictors = NULL, engine = "glm", ...) {
  if (!inherits(task, "gp3ml_task") || task$task_type != "classification") .gp3ml_stop("`task` must be a binary classification task.")
  fit_gazepoint_model(data, task, predictors, engine, ...)
}

#' Predict from a gp3ml model
#'
#' @param object A fitted `gp3ml_model` object.
#' @param newdata New data containing the required predictors.
#' @param type Requested prediction type.
#' @param ... Additional arguments passed to custom prediction methods.
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
#' model <- train_gazepoint_classifier(
#'   data = example_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' probability <- predict(
#'   model,
#'   example_data,
#'   type = "probability"
#' )
#' predicted_class <- predict(
#'   model,
#'   example_data,
#'   type = "class"
#' )
#' head(probability)
#' head(predicted_class)
#' @return For classification with `type = "class"`, a factor of predicted classes. Otherwise, a numeric vector of probabilities, link-scale values, or regression predictions.
#' @method predict gp3ml_model
#' @export
predict.gp3ml_model <- function(object, newdata, type = c("response", "probability", "class", "link"), ...) {
  type <- match.arg(type)
  x <- bake_gazepoint_preprocessor(object$preprocessor, newdata)
  task <- object$task
  if (!is.null(object$engine_spec)) {
    raw <- object$engine_spec$predict_fun(fit = object$fit, newdata = x, type = type, task = task, ...)
  } else if (object$engine == "glm") {
    raw <- as.numeric(stats::predict(object$fit, newdata = as.data.frame(x, check.names = FALSE), type = if (type == "link") "link" else "response"))
  } else if (object$engine == "lm") {
    raw <- as.numeric(stats::predict(object$fit, newdata = as.data.frame(x, check.names = FALSE)))
  } else if (object$engine == "ranger") {
    pred <- stats::predict(object$fit, data = as.data.frame(x))$predictions
    raw <- if (task$task_type == "classification") {
      if (is.matrix(pred)) pred[, "1"] else as.numeric(pred)
    } else as.numeric(pred)
  } else if (object$engine == "xgboost") {
    raw <- as.numeric(stats::predict(object$fit, x))
  } else if (object$engine == "nnet") {
    raw <- as.numeric(stats::predict(object$fit, x, type = "raw"))
  } else if (object$engine == "keras3") {
    raw <- as.numeric(object$fit$predict(x, verbose = 0L))
  } else .gp3ml_stop("Unsupported fitted engine `%s`.", object$engine)
  if (task$task_type == "classification") {
    if (type == "class") return(factor(ifelse(raw >= object$threshold, task$positive, task$negative), levels = task$levels))
    return(.gp3ml_clip_probability(raw))
  }
  raw
}

#' @method print gp3ml_model
#' @export
print.gp3ml_model <- function(x, ...) {
  cat("<gp3ml_model> engine=", x$engine, " task=", x$task$task_type, " n=", x$training_n, " predictors=", length(x$predictors), "\n", sep = "")
  invisible(x)
}
