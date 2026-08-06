# Audit deviations from a locked analysis plan

Audit deviations from a locked analysis plan

## Usage

``` r
audit_gazepoint_plan_deviations(
  plan,
  actual,
  fields = c("outcome", "predictors", "generalization_target", "primary_metric",
    "secondary_metrics", "calibration_metric", "uncertainty_method", "threshold_policy",
    "candidate_models", "preprocessing_plan")
)
```

## Arguments

- plan:

  A locked analysis plan.

- actual:

  Named list describing the analysis actually performed.

- fields:

  Fields to compare.

## Value

A `gp3ml_plan_deviation_audit`.
