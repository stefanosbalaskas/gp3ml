# Audit predictor distribution shift

Audit predictor distribution shift

## Usage

``` r
audit_gazepoint_dataset_shift(
  development,
  external,
  predictors = intersect(names(development), names(external)),
  thresholds = list(smd_review = 0.2, smd_fail = 0.5, outside_review = 0.05, outside_fail
    = 0.2, tv_review = 0.2, tv_fail = 0.4)
)
```

## Arguments

- development:

  Development/training data.

- external:

  Independent or later data to compare.

- predictors:

  Predictors to audit. Defaults to common columns.

- thresholds:

  Named threshold list.

## Value

A `gp3ml_dataset_shift_audit`.
