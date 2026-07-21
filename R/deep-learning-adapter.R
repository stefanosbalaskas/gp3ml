#' Fit an optional governed deep-learning model through keras3
#'
#' @param data Analysis data used to fit the network.
#' @param task A governed `gp3ml_task` object.
#' @param predictors Optional character vector of predictor columns.
#' @param preprocessor Optional fitted preprocessing object.
#' @param hidden_units Integer vector of hidden-layer sizes.
#' @param dropout Dropout proportion applied after hidden layers.
#' @param epochs Number of training epochs.
#' @param batch_size Training batch size.
#' @param validation_split Proportion reserved for internal validation.
#' @param optimizer Keras optimizer name or object.
#' @param seed Deterministic random seed.
#' @param verbose Keras training verbosity.
#'
#' @examplesIf requireNamespace("keras3", quietly = TRUE) && identical(Sys.getenv("GP3ML_RUN_KERAS_EXAMPLES"), "true")
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
#' deep_model <- fit_gazepoint_deep_model(
#'   data = example_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   hidden_units = 4L,
#'   dropout = 0,
#'   epochs = 1L,
#'   batch_size = 8L,
#'   validation_split = 0,
#'   seed = 101L,
#'   verbose = 0L
#' )
#' deep_model
#' @return A governed `gp3ml_model` object containing the fitted `keras3` model, training history, preprocessing object, task contract, and training metadata.
#' @export
fit_gazepoint_deep_model <- function(
    data,
    task,
    predictors = NULL,
    preprocessor = NULL,
    hidden_units = c(64L, 32L),
    dropout = 0.2,
    epochs = 50L,
    batch_size = 32L,
    validation_split = 0.2,
    optimizer = "adam",
    seed = 1L,
    verbose = 0L) {
  if (!requireNamespace("keras3", quietly = TRUE)) .gp3ml_stop("Install `keras3` and configure a backend to use deep learning.")
  assert_gp3ml_use_case(task, data)
  predictors <- predictors %||% .gp3ml_default_predictors(data, task)
  preprocessor <- preprocessor %||% fit_gazepoint_preprocessor(data, predictors)
  x <- bake_gazepoint_preprocessor(preprocessor, data)
  y <- if (task$task_type == "classification") as.integer(as.character(data[[task$outcome]]) == task$positive) else as.numeric(data[[task$outcome]])
  keras3::set_random_seed(as.integer(seed))
  model <- keras3::keras_model_sequential()
  model$add(keras3::layer_dense(units = as.integer(hidden_units[[1L]]), activation = "relu", input_shape = c(ncol(x))))
  if (dropout > 0) model$add(keras3::layer_dropout(rate = dropout))
  if (length(hidden_units) > 1L) {
    for (units in hidden_units[-1L]) {
      model$add(keras3::layer_dense(units = as.integer(units), activation = "relu"))
      if (dropout > 0) model$add(keras3::layer_dropout(rate = dropout))
    }
  }
  model$add(keras3::layer_dense(units = 1L, activation = if (task$task_type == "classification") "sigmoid" else "linear"))
  model$compile(optimizer = optimizer, loss = if (task$task_type == "classification") "binary_crossentropy" else "mean_squared_error", metrics = if (task$task_type == "classification") list("accuracy") else list("mean_absolute_error"))
  history <- model$fit(x, y, epochs = as.integer(epochs), batch_size = as.integer(batch_size), validation_split = validation_split, verbose = verbose)
  structure(list(fit = model, history = history, engine = "keras3", engine_spec = NULL, engine_args = list(hidden_units = hidden_units, dropout = dropout, epochs = epochs, batch_size = batch_size), task = task, predictors = predictors, preprocessor = preprocessor, threshold = 0.5, seed = seed, training_n = nrow(data), outcome_distribution = table(data[[task$outcome]], useNA = "ifany"), predictor_summary = .gp3ml_training_summary(data, predictors), training_hash = .gp3ml_hash_object(data[c(task$outcome, predictors)]), call = match.call()), class = "gp3ml_model")
}
