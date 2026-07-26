# Evaluate leave-one-feature-out stability

Evaluate leave-one-feature-out stability

## Usage

``` r
evaluate_gazepoint_feature_stability(features, evaluator, ...)
```

## Arguments

- features:

  Predictor names.

- evaluator:

  Function called as `evaluator(excluded_feature = feature, ...)`.

- ...:

  Additional evaluator arguments.

## Value

A `gp3ml_stability_evaluation`.
