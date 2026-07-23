# Predict from a gp3ml model

Predict from a gp3ml model

## Usage

``` r
# S3 method for class 'gp3ml_model'
predict(
  object,
  newdata,
  type = c("response", "probability", "class", "link"),
  ...
)
```

## Arguments

- object:

  A fitted `gp3ml_model` object.

- newdata:

  New data containing the required predictors.

- type:

  Requested prediction type.

- ...:

  Additional arguments passed to custom prediction methods.

## Value

For classification with `type = "class"`, a factor of predicted classes.
Otherwise, a numeric vector of probabilities, link-scale values, or
regression predictions.

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
probability <- predict(
  model,
  example_data,
  type = "probability"
)
predicted_class <- predict(
  model,
  example_data,
  type = "class"
)
head(probability)
#> [1] 0.4995214 0.5130655 0.5235884 0.5300118 0.5317168 0.5285952
head(predicted_class)
#> [1] pass   review review review review review
#> Levels: pass review
```
