# Fit a governed Gazepoint model

Fit a governed Gazepoint model

## Usage

``` r
fit_gazepoint_model(
  data,
  task,
  predictors = NULL,
  engine = NULL,
  preprocessor = NULL,
  preprocessor_args = list(),
  engine_args = list(),
  seed = 1L,
  threshold = 0.5
)
```

## Arguments

- data:

  Analysis data used to fit the model.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Optional character vector of predictor columns.

- engine:

  Engine name or controlled custom-engine object.

- preprocessor:

  Optional fitted preprocessing object.

- preprocessor_args:

  Arguments passed to preprocessing fitting.

- engine_args:

  Arguments passed to the model engine.

- seed:

  Deterministic random seed.

- threshold:

  Classification probability threshold.

## Value

A governed `gp3ml_model` object containing the fitted engine,
preprocessing object, task contract, predictors, and training metadata.

## Examples

``` r
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
model <- fit_gazepoint_model(
  data = example_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  engine = "glm",
  seed = 101L
)
model
#> <gp3ml_model> engine=glm task=classification n=24 predictors=2
```
