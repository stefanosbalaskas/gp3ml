# Print feature-manifest validation

Print feature-manifest validation

## Usage

``` r
# S3 method for class 'gazepoint_feature_manifest_validation'
print(x, ...)
```

## Arguments

- x:

  An object returned by
  [`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_feature_manifest.md).

- ...:

  Additional arguments, currently unused.

## Value

`x`, invisibly.

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
validation <- validate_gazepoint_feature_manifest(manifest)
print(validation)
#> <gazepoint_feature_manifest_validation>
#> Overall status: PASS
#> Features: 1
#> Non-passing checks: 0
#>  status n_checks
#>  pass   11
#>  review  0
#>  fail    0
```
