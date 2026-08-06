# Audit multiple robustness dimensions

Audit multiple robustness dimensions

## Usage

``` r
audit_gazepoint_model_robustness(
  seed_stability = NULL,
  feature_stability = NULL,
  threshold_stability = NULL,
  missingness_stability = NULL,
  relative_sd_review = 0.05,
  relative_sd_fail = 0.15
)
```

## Arguments

- seed_stability:

  Optional seed-stability object.

- feature_stability:

  Optional feature-stability object.

- threshold_stability:

  Optional threshold-stability object.

- missingness_stability:

  Optional missingness-stability object.

- relative_sd_review:

  Relative SD threshold for review.

- relative_sd_fail:

  Relative SD threshold for fail.

## Value

A `gp3ml_model_robustness_audit`.
