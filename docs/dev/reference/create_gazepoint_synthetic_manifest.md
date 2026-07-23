# Create a synthetic governed feature manifest

Create a synthetic governed feature manifest

## Usage

``` r
create_gazepoint_synthetic_manifest(
  outcome,
  predictors,
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  trial_id = "trial_id"
)
```

## Arguments

- outcome:

  Name of the observed synthetic outcome.

- predictors:

  Predictor names to declare.

- participant_id:

  Participant identifier column.

- stimulus_id:

  Stimulus identifier column.

- trial_id:

  Trial identifier column.

## Value

A `gazepoint_feature_manifest` produced by
[`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_feature_manifest.md).

## Examples

``` r
create_gazepoint_synthetic_manifest(
  outcome = "quality_status",
  predictors = c("tracking_ratio", "blink_rate", "gaze_dispersion")
)
#>           feature                     scientific_source
#> 1  tracking_ratio Deterministic synthetic demonstration
#> 2      blink_rate Deterministic synthetic demonstration
#> 3 gaze_dispersion Deterministic synthetic demonstration
#>               source_table                transformation availability_stage
#> 1 synthetic_trial_features Predeclared synthetic feature    during_exposure
#> 2 synthetic_trial_features Predeclared synthetic feature    during_exposure
#> 3 synthetic_trial_features Predeclared synthetic feature    during_exposure
#>   prediction_time_available outcome_derived post_outcome identifier
#> 1                      TRUE           FALSE        FALSE      FALSE
#> 2                      TRUE           FALSE        FALSE      FALSE
#> 3                      TRUE           FALSE        FALSE      FALSE
#>   preprocessing_scope fold_local_required
#> 1     resampling_fold                TRUE
#> 2     resampling_fold                TRUE
#> 3     resampling_fold                TRUE
#>                                                            reviewer_notes
#> 1 Outcome `quality_status` is explicitly observed and is not a predictor.
#> 2 Outcome `quality_status` is explicitly observed and is not a predictor.
#> 3 Outcome `quality_status` is explicitly observed and is not a predictor.
```
