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
