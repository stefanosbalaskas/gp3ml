# Generic governed binary-classifier training wrapper

Generic governed binary-classifier training wrapper

## Usage

``` r
train_gazepoint_classifier(data, task, predictors = NULL, engine = "glm", ...)
```

## Arguments

- data:

  Analysis data used to train the classifier.

- task:

  A governed binary-classification task.

- predictors:

  Optional character vector of predictor columns.

- engine:

  Classification engine name or custom engine.

- ...:

  Additional arguments passed to
  [`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_model.md).

## Value

A governed classification `gp3ml_model` object returned by
[`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_model.md).

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
model <- train_gazepoint_classifier(
  data = example_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  engine = "glm",
  seed = 101L
)
model
#> <gp3ml_model> engine=glm task=classification n=24 predictors=2
```
