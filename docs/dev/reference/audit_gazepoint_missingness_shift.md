# Audit missingness shift

Audit missingness shift

## Usage

``` r
audit_gazepoint_missingness_shift(
  development,
  external,
  predictors = intersect(names(development), names(external)),
  review_delta = 0.1,
  fail_delta = 0.25
)
```

## Arguments

- development:

  Development data.

- external:

  External/new data.

- predictors:

  Predictors to audit.

- review_delta:

  Review threshold for absolute missingness change.

- fail_delta:

  Fail threshold for absolute missingness change.

## Value

A `gp3ml_missingness_shift_audit`.
