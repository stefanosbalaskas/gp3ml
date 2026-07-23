# Evaluate every governed candidate on the same grouped folds

Evaluate every governed candidate on the same grouped folds

## Usage

``` r
tune_gazepoint_model(
  folds,
  task,
  tuning_grid,
  predictors = NULL,
  metrics = NULL,
  seed = 1L,
  continue_on_error = TRUE,
  keep_evaluations = TRUE
)

# S3 method for class 'gp3ml_model_tuning'
print(x, ...)
```

## Arguments

- folds:

  A `gazepoint_group_folds` object.

- task:

  A governed task.

- tuning_grid:

  A `gp3ml_tuning_grid`.

- predictors:

  Optional declared predictors.

- metrics:

  Optional metric names retained in the comparison table.

- seed:

  Base deterministic seed.

- continue_on_error:

  Whether failed candidates remain in the result while later candidates
  continue.

- keep_evaluations:

  Whether complete candidate evaluations are retained.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_model_tuning` object retaining all candidates and failures.

## Examples

``` r
data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 202L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
folds <- create_gazepoint_group_folds(
  data, "quality_status", predictors, manifest,
  "new_participants", "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 1L, seed = 202L
)
task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
grid <- create_gazepoint_tuning_grid(
  "glm",
  preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
  thresholds = 0.5
)
tuned <- tune_gazepoint_model(folds, task, grid, predictors, seed = 202L)
tuned
#> <gp3ml_model_tuning>
#>   Candidates: 2
#>   Failed candidates: 0
#>   Automatic winner: none
```
