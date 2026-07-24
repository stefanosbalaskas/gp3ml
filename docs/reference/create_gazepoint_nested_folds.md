# Create nested grouped resampling from mature outer folds

Inner folds are constructed only from each outer analysis partition and
preserve the declared participant/stimulus generalization target. The
outer assessment partition is never used for inner preprocessing or
tuning.

## Usage

``` r
create_gazepoint_nested_folds(
  outer_folds,
  inner_v = 3L,
  inner_repeats = 1L,
  seed = 1L,
  continue_on_error = FALSE
)

# S3 method for class 'gp3ml_nested_folds'
print(x, ...)
```

## Arguments

- outer_folds:

  A validated `gazepoint_group_folds` object.

- inner_v:

  Number of inner folds.

- inner_repeats:

  Number of inner repeats.

- seed:

  Base deterministic seed.

- continue_on_error:

  Whether infeasible outer folds are retained as failures instead of
  stopping immediately.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_nested_folds` object.

## Examples

``` r
data <- simulate_gazepoint_governed_data(16L, 4L, 1L, 303L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
manifest <- create_gazepoint_synthetic_manifest("quality_status", predictors)
outer <- create_gazepoint_group_folds(
  data, "quality_status", predictors, manifest,
  "new_participants", "participant_id", "trial_id", "stimulus_id",
  v = 4L, repeats = 1L, seed = 303L
)
nested <- create_gazepoint_nested_folds(
  outer,
  inner_v = 3L,
  inner_repeats = 1L,
  seed = 303L
)
nested
#> <gp3ml_nested_folds>
#>   Outer folds: 4
#>   Inner v/repeats: 3/1
#>   Target: new_participants
#>   Audit: pass
```
