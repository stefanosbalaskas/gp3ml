# Fit a probability calibrator

Fit a probability calibrator

## Usage

``` r
fit_gazepoint_calibrator(
  truth,
  probability,
  positive = NULL,
  method = c("platt", "isotonic")
)
```

## Arguments

- truth:

  Observed binary outcome values.

- probability:

  Uncalibrated positive-class probabilities.

- positive:

  Label representing the positive class.

- method:

  Calibration method: Platt scaling or isotonic regression.
