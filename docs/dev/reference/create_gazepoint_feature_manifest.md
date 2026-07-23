# Create a Gazepoint feature-provenance manifest

Creates a structured provenance manifest for intended predictive
features. Each row records where a feature originated, when it became
available, whether it is outcome-derived or post-outcome, and where any
data-dependent preprocessing was estimated.

## Usage

``` r
create_gazepoint_feature_manifest(
  features,
  scientific_source = NA_character_,
  source_table = NA_character_,
  transformation = "none",
  availability_stage = "unknown",
  prediction_time_available = NA,
  outcome_derived = FALSE,
  post_outcome = FALSE,
  identifier = FALSE,
  preprocessing_scope = "unknown",
  fold_local_required = NA,
  reviewer_notes = ""
)
```

## Arguments

- features:

  Character vector of unique feature names.

- scientific_source:

  Scientific or measurement source for each feature.

- source_table:

  Source export, table, or object for each feature.

- transformation:

  Description of the transformation used to construct each feature.

- availability_stage:

  Availability stage for each feature. One of `"pre_exposure"`,
  `"during_exposure"`, `"post_exposure_pre_outcome"`, `"at_prediction"`,
  `"post_outcome"`, or `"unknown"`.

- prediction_time_available:

  Logical vector indicating whether each feature is available at the
  intended prediction time.

- outcome_derived:

  Logical vector indicating whether each feature was derived directly or
  indirectly from the outcome.

- post_outcome:

  Logical vector indicating whether each feature was measured or
  constructed after the outcome became available.

- identifier:

  Logical vector indicating whether each feature is an identifier or
  row-location variable.

- preprocessing_scope:

  Scope in which any data-dependent preprocessing was estimated. One of
  `"none"`, `"global"`, `"analysis_partition"`, `"resampling_fold"`, or
  `"unknown"`.

- fold_local_required:

  Logical vector indicating whether preprocessing for each feature must
  be estimated separately inside each resampling fold.

- reviewer_notes:

  Optional reviewer-facing notes.

## Value

A data frame of class `gazepoint_feature_manifest`.

## Details

Each row is treated as an intended predictor. Consequently,
outcome-derived, post-outcome, unavailable, and identifier features are
treated as failing conditions by
[`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_feature_manifest.md).

The manifest records declared provenance. It does not independently
prove that preprocessing was estimated within the stated scope.

## Examples

``` r
manifest <- create_gazepoint_feature_manifest(
  features = c("fixation_duration", "pupil_change"),
  scientific_source = c(
    "Gazepoint fixation export",
    "Gazepoint all-gaze export"
  ),
  source_table = c("fixations", "all_gaze"),
  transformation = c(
    "Trial-level mean",
    "Baseline-adjusted change"
  ),
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = c("none", "resampling_fold"),
  fold_local_required = c(FALSE, TRUE)
)

manifest
#>             feature         scientific_source source_table
#> 1 fixation_duration Gazepoint fixation export    fixations
#> 2      pupil_change Gazepoint all-gaze export     all_gaze
#>             transformation availability_stage prediction_time_available
#> 1         Trial-level mean    during_exposure                      TRUE
#> 2 Baseline-adjusted change    during_exposure                      TRUE
#>   outcome_derived post_outcome identifier preprocessing_scope
#> 1           FALSE        FALSE      FALSE                none
#> 2           FALSE        FALSE      FALSE     resampling_fold
#>   fold_local_required reviewer_notes
#> 1               FALSE
#> 2                TRUE
```
