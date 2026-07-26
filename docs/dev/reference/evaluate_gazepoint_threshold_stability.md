# Evaluate threshold stability around the optimum

Evaluate threshold stability around the optimum

## Usage

``` r
evaluate_gazepoint_threshold_stability(
  evaluation,
  metric,
  direction = c("maximize", "minimize"),
  tolerance = 0.02
)
```

## Arguments

- evaluation:

  Threshold evaluation.

- metric:

  Metric.

- direction:

  Optimization direction.

- tolerance:

  Fractional tolerance from the optimum.

## Value

A `gp3ml_threshold_stability`.
