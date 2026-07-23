# Task-aware performance metrics

Task-aware performance metrics

## Usage

``` r
gazepoint_performance_metrics(
  task,
  truth,
  prediction = NULL,
  probability = NULL,
  threshold = 0.5
)
```

## Arguments

- task:

  A governed `gp3ml_task` object.

- truth:

  Observed outcome values.

- prediction:

  Predicted classes or numeric values.

- probability:

  Predicted positive-class probabilities.

- threshold:

  Probability threshold for classification.

## Value

A one-row data frame of classification or regression metrics selected
according to the governed task type.

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
probability <- seq(
  0.20,
  0.80,
  length.out = nrow(example_data)
)
predicted <- factor(
  ifelse(probability >= 0.5, "review", "pass"),
  levels = levels(example_data$quality_status)
)
gazepoint_performance_metrics(
  task = task,
  truth = example_data$quality_status,
  prediction = predicted,
  probability = probability
)
#>    n threshold accuracy balanced_accuracy sensitivity specificity precision
#> 1 24       0.5      0.5               0.5         0.5         0.5       0.5
#>   recall  f1 mcc roc_auc    pr_auc     brier  log_loss
#> 1    0.5 0.5   0     0.5 0.5625259 0.2826087 0.7657243
```
