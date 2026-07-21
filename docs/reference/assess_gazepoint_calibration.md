# Calibration assessment with bootstrap uncertainty

Calibration assessment with bootstrap uncertainty

## Usage

``` r
assess_gazepoint_calibration(
  truth,
  probability,
  positive = NULL,
  bins = 10L,
  bootstrap = 200L,
  conf_level = 0.95,
  seed = 1L
)
```

## Arguments

- truth:

  Observed binary outcome values.

- probability:

  Predicted positive-class probabilities.

- positive:

  Label representing the positive class.

- bins:

  Number of reliability bins.

- bootstrap:

  Number of bootstrap replicates.

- conf_level:

  Confidence level for percentile intervals.

- seed:

  Deterministic random seed.

## Value

A `gp3ml_calibration_assessment` object containing calibration
summaries, reliability-bin results, bootstrap intervals, and assessment
settings.

## Examples

``` r
truth <- factor(
  rep(rep(c("pass", "review"), 5), 10),
  levels = c("pass", "review")
)
probability <- rep(
  seq(0.10, 0.90, length.out = 10),
  each = 10
)

assessment <- assess_gazepoint_calibration(
  truth = truth,
  probability = probability,
  positive = "review",
  bins = 5L,
  bootstrap = 10L,
  seed = 101L
)
assessment
#> <gp3ml_calibration_assessment>
#>      intercept        slope     brier  log_loss       ece
#>  -4.929524e-32 1.387538e-16 0.3151852 0.8744536 0.2133333
```
