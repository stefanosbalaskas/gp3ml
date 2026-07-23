# Fit an optional governed deep-learning model through keras3

Fit an optional governed deep-learning model through keras3

## Usage

``` r
fit_gazepoint_deep_model(
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
  verbose = 0L
)
```

## Arguments

- data:

  Analysis data used to fit the network.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Optional character vector of predictor columns.

- preprocessor:

  Optional fitted preprocessing object.

- hidden_units:

  Integer vector of hidden-layer sizes.

- dropout:

  Dropout proportion applied after hidden layers.

- epochs:

  Number of training epochs.

- batch_size:

  Training batch size.

- validation_split:

  Proportion reserved for internal validation.

- optimizer:

  Keras optimizer name or object.

- seed:

  Deterministic random seed.

- verbose:

  Keras training verbosity.

## Value

A governed `gp3ml_model` object containing the fitted `keras3` model,
training history, preprocessing object, task contract, and training
metadata.

## Examples

``` r
if (FALSE) { # requireNamespace("keras3", quietly = TRUE) && identical(Sys.getenv("GP3ML_RUN_KERAS_EXAMPLES"), "true")
example_data <- data.frame(
  participant_id = rep(sprintf("P%02d", 1:12), each = 2),
  trial_id = sprintf("T%02d", 1:24),
  stimulus_id = rep(c("S01", "S02"), 12),
  condition = rep(c("A", "B"), 12),
  fixation_duration = 180 + seq_len(24),
  pupil_change = sin(seq_len(24) / 3),
  stringsAsFactors = FALSE
)
example_data$quality_status <- factor(
  c(
    "pass", "review", "pass", "review", "review", "pass",
    "review", "pass", "pass", "review", "review", "pass",
    "review", "pass", "review", "pass", "pass", "review",
    "pass", "review", "review", "pass", "pass", "review"
  ),
  levels = c("pass", "review")
)
task <- declare_gazepoint_task(
  data = example_data,
  outcome = "quality_status",
  purpose = "Predict predefined recording-quality review status",
  task_type = "classification",
  unit_id = "trial_id",
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants",
  positive = "review"
)
deep_model <- fit_gazepoint_deep_model(
  data = example_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  hidden_units = 4L,
  dropout = 0,
  epochs = 1L,
  batch_size = 8L,
  validation_split = 0,
  seed = 101L,
  verbose = 0L
)
deep_model
}
```
