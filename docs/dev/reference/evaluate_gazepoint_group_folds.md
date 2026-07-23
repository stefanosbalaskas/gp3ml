# Evaluate a governed model specification across materialized grouped folds

Fits preprocessing and the requested model only on each fold's analysis
partition, predicts only on the corresponding assessment partition,
retains excluded rows, and records fold-level metrics, leakage audits,
warnings, and failures. Row-level predictions are never relabelled as
participant- or stimulus-level estimates.

## Usage

``` r
evaluate_gazepoint_group_folds(
  folds,
  task,
  predictors = NULL,
  engine = NULL,
  preprocessor_args = list(),
  engine_args = list(),
  threshold = 0.5,
  seed = 1L,
  assess_calibration = FALSE,
  calibration_bins = 10L,
  calibration_bootstrap = 0L,
  keep_models = FALSE,
  continue_on_error = TRUE
)

# S3 method for class 'gp3ml_resample_evaluation'
print(x, ...)
```

## Arguments

- folds:

  A mature `gazepoint_group_folds` object containing materialized folds
  under `folds$folds`.

- task:

  A governed `gp3ml_task` compatible with the fold metadata.

- predictors:

  Optional predictor names. Defaults to the fold metadata.

- engine:

  Model engine name or governed custom engine.

- preprocessor_args:

  Arguments passed to
  [`fit_gazepoint_preprocessor()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_preprocessor.md).

- engine_args:

  Arguments passed to
  [`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_model.md).

- threshold:

  Classification threshold.

- seed:

  Base deterministic seed.

- assess_calibration:

  Whether to calculate assessment-fold calibration summaries for
  classification tasks.

- calibration_bins:

  Number of reliability bins.

- calibration_bootstrap:

  Calibration bootstrap replicates. Use zero in fast smoke tests.

- keep_models:

  Whether fitted fold models are retained.

- continue_on_error:

  Whether later folds continue after a failed fold.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_resample_evaluation` object.

## Examples

``` r
data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 101L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
folds <- create_gazepoint_group_folds(
  data = data,
  outcome = "quality_status",
  predictors = predictors,
  feature_manifest = manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  v = 3L,
  repeats = 1L,
  seed = 101L
)
task <- create_gazepoint_synthetic_task(
  data,
  "recording_quality",
  "new_participants"
)
evaluation <- evaluate_gazepoint_group_folds(
  folds,
  task,
  predictors = predictors,
  engine = "glm",
  seed = 101L
)
evaluation
#> <gp3ml_resample_evaluation>
#>   Target: new_participants
#>   Engine: glm
#>   Folds: 3
#>   Passed/review/failed: 0/3/0
#>   Predictions: 48
```
