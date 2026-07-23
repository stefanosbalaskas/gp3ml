# Create an external-validation report object

Create an external-validation report object

## Usage

``` r
create_external_validation_report(
  validation,
  development_metrics = NULL,
  limitations = character()
)
```

## Arguments

- validation:

  A `gp3ml_external_validation` object.

- development_metrics:

  Optional development-sample metrics.

- limitations:

  Character vector describing report limitations.

## Value

A `gp3ml_external_validation_report` object containing the validation
result, optional development metrics, limitations, and prohibited-use
information.

## Examples

``` r
training_data <- data.frame(
  participant_id = rep(sprintf("P%02d", 1:12), each = 2),
  trial_id = sprintf("T%02d", 1:24),
  stimulus_id = rep(c("S01", "S02"), 12),
  fixation_duration = 180 + seq_len(24),
  pupil_change = sin(seq_len(24) / 3),
  stringsAsFactors = FALSE
)
training_data$quality_status <- factor(
  c(
    "pass", "review", "pass", "review", "review", "pass",
    "review", "pass", "pass", "review", "review", "pass",
    "review", "pass", "review", "pass", "pass", "review",
    "pass", "review", "review", "pass", "pass", "review"
  ),
  levels = c("pass", "review")
)
task <- declare_gazepoint_task(
  data = training_data,
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
  data = training_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  engine = "glm",
  seed = 101L
)
external_data <- training_data
external_data$participant_id <- rep(
  sprintf("E%02d", 1:12),
  each = 2
)
external_data$trial_id <- sprintf("ET%02d", 1:24)
external_data$fixation_duration <-
  external_data$fixation_duration + 4
external_data$pupil_change <- cos(seq_len(24) / 4)
validation <- evaluate_external_validation(
  model = model,
  external_data = external_data,
  label = "synthetic_external",
  bootstrap = 10L,
  seed = 101L
)
report <- create_external_validation_report(
  validation = validation,
  limitations = "Synthetic external-validation example."
)
report
#> $validation
#> <gp3ml_external_validation> synthetic_external
#>   n threshold  accuracy balanced_accuracy sensitivity specificity precision
#>  24       0.5 0.5416667         0.5416667         0.5   0.5833333 0.5454545
#>  recall        f1       mcc roc_auc    pr_auc     brier  log_loss
#>     0.5 0.5217391 0.0836242     0.5 0.5550724 0.2505173 0.6941939
#>
#> $development_metrics
#> NULL
#>
#> $limitations
#> [1] "Synthetic external-validation example."
#>
#> $prohibited_uses
#> [1] "person identification or re-identification"
#> [2] "biometric authentication or verification"
#> [3] "health, disease, disability, or diagnostic inference"
#> [4] "protected-attribute prediction or proxy prediction"
#> [5] "emotion, stress, personality, deception, cognition, comprehension, intent, or mental-state inference"
#> [6] "random row-level evaluation represented as participant- or stimulus-level generalization"
#> [7] "outcome-derived or post-outcome feature engineering"
#> [8] "preprocessing estimated using assessment or external-validation data"
#> [9] "accuracy-only reporting without discrimination, calibration, and uncertainty"
#>
#> attr(,"class")
#> [1] "gp3ml_external_validation_report"
```
