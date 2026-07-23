# Validate a Gazepoint feature-provenance manifest

Validates the schema and declared scientific safeguards in a feature
manifest. Schema errors stop execution. Substantive concerns are
returned as structured `pass`, `review`, or `fail` checks.

## Usage

``` r
validate_gazepoint_feature_manifest(x)
```

## Arguments

- x:

  A feature manifest created by
  [`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_feature_manifest.md)
  or a compatible data frame.

## Value

An object of class `gazepoint_feature_manifest_validation` containing
the overall status, complete checks, non-passing issues, and validated
manifest.

## Details

A manifest fails when an intended predictor is declared as
outcome-derived, post-outcome, unavailable at prediction time, or an
identifier. It also fails when fold-local estimation is required but
preprocessing is declared outside the resampling fold.

Unknown or incomplete provenance is returned for review rather than
treated as evidence that a safeguard was satisfied.

## Examples

``` r
manifest <- create_gazepoint_feature_manifest(
  features = "fixation_duration",
  scientific_source = "Gazepoint fixation export",
  source_table = "fixations",
  transformation = "Trial-level mean",
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = "none",
  fold_local_required = FALSE
)

validate_gazepoint_feature_manifest(manifest)
#> <gazepoint_feature_manifest_validation>
#> Overall status: PASS
#> Features: 1
#> Non-passing checks: 0
#>  status n_checks
#>  pass   11
#>  review  0
#>  fail    0
```
