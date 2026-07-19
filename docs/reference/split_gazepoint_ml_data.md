# Create a deterministic group-aware Gazepoint holdout split

Creates analysis and assessment partitions that preserve the grouping
unit implied by an explicit generalization target.

## Usage

``` r
split_gazepoint_ml_data(
  data,
  outcome,
  predictors,
  feature_manifest,
  generalization_target,
  participant_id = NULL,
  trial_id = NULL,
  stimulus_id = NULL,
  assessment_prop = 0.2,
  seed = 1L,
  source_row_id = ".gp3ml_source_row"
)
```

## Arguments

- data:

  Data frame containing the outcome, predictors, and grouping
  identifiers.

- outcome:

  Name of the outcome column.

- predictors:

  Character vector of predictor-column names.

- feature_manifest:

  Feature manifest containing the predictors.

- generalization_target:

  Declared predictive-generalization target.

- participant_id:

  Optional participant-identifier column.

- trial_id:

  Optional trial-identifier column.

- stimulus_id:

  Optional stimulus-identifier column.

- assessment_prop:

  Requested assessment proportion.

- seed:

  Integer random seed.

- source_row_id:

  Name of the source-row identifier added to the returned partitions.

## Value

An object of class `gazepoint_ml_split`.

## Details

For simultaneous participant and stimulus generalization, cross-block
rows are placed in the excluded partition.

This function does not perform preprocessing, feature selection,
resampling, or model fitting.
