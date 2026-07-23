# Contaminated feature manifests and leakage cases

## Clean manifest

``` r

data <- simulate_gazepoint_governed_data(12L, 4L, 1L, seed = 2701L)
predictors <- c("tracking_ratio", "blink_rate")
clean <- create_gazepoint_synthetic_manifest("quality_status", predictors)
validate_gazepoint_feature_manifest(clean)
#> <gazepoint_feature_manifest_validation>
#> Overall status: PASS
#> Features: 2
#> Non-passing checks: 0
#>  status n_checks
#>  pass   22
#>  review  0
#>  fail    0
```

## Deliberate post-outcome contamination

``` r

contaminated <- create_gazepoint_feature_manifest(
  features = c("tracking_ratio", "outcome_summary"),
  scientific_source = c("Synthetic export", "Derived from observed outcome"),
  source_table = c("trial_features", "outcome_table"),
  transformation = c("Predeclared", "Post-outcome aggregation"),
  availability_stage = c("during_exposure", "post_outcome"),
  prediction_time_available = c(TRUE, FALSE),
  outcome_derived = c(FALSE, TRUE),
  post_outcome = c(FALSE, TRUE),
  identifier = FALSE,
  preprocessing_scope = c("resampling_fold", "none"),
  fold_local_required = c(TRUE, FALSE),
  reviewer_notes = c("Permitted synthetic feature", "Deliberate contaminated case")
)
validation <- validate_gazepoint_feature_manifest(contaminated)
validation
#> <gazepoint_feature_manifest_validation>
#> Overall status: FAIL
#> Features: 2
#> Non-passing checks: 3
#>  status n_checks
#>  pass   19
#>  review  0
#>  fail    3
```

A contaminated manifest must fail or require explicit review before
fitting. The example is included to exercise the governance boundary,
not to normalize contaminated predictors.
