# Bootstrap uncertainty intervals for performance metrics

Bootstrap uncertainty intervals for performance metrics

## Usage

``` r
bootstrap_gazepoint_metrics(
  task,
  truth,
  prediction = NULL,
  probability = NULL,
  threshold = 0.5,
  bootstrap = 1000L,
  conf_level = 0.95,
  seed = 1L
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

- bootstrap:

  Number of bootstrap replicates.

- conf_level:

  Confidence level for percentile intervals.

- seed:

  Deterministic random seed.

## Value

A `gp3ml_metric_uncertainty` object containing point estimates,
percentile intervals, bootstrap draws, resampling settings, and the
governed task.

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
uncertainty <- bootstrap_gazepoint_metrics(
  task = task,
  truth = example_data$quality_status,
  prediction = predicted,
  probability = probability,
  bootstrap = 10L,
  seed = 101L
)
uncertainty
#> <gp3ml_metric_uncertainty> bootstrap=10 confidence=0.95
#>             metric  estimate      lower     upper
#>           accuracy 0.5000000  0.3750000 0.6250000
#>  balanced_accuracy 0.5000000  0.3750000 0.6250000
#>        sensitivity 0.5000000  0.3520833 0.7500000
#>        specificity 0.5000000  0.3520833 0.5000000
#>          precision 0.5000000  0.3683566 0.6000000
#>             recall 0.5000000  0.3520833 0.7500000
#>                 f1 0.5000000  0.3595652 0.6666667
#>                mcc 0.0000000 -0.2508726 0.2581989
#>            roc_auc 0.5000000  0.2986111 0.6234375
#>             pr_auc 0.5625259  0.4115008 0.7020094
#>              brier 0.2826087  0.2408956 0.3429927
#>           log_loss 0.7657243  0.6745589 0.9010546
```
