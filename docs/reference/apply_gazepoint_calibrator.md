# Apply a fitted probability calibrator

Apply a fitted probability calibrator

## Usage

``` r
apply_gazepoint_calibrator(calibrator, probability)
```

## Arguments

- calibrator:

  A fitted `gp3ml_calibrator` object.

- probability:

  Uncalibrated probabilities to transform.

## Value

A numeric vector of calibrated probabilities, clipped to the open unit
interval.

## Examples

``` r
truth <- factor(
  rep(c("pass", "review"), 6),
  levels = c("pass", "review")
)
probability <- c(
  0.20, 0.70, 0.60, 0.55, 0.30, 0.80,
  0.65, 0.45, 0.40, 0.75, 0.50, 0.60
)
calibrator <- fit_gazepoint_calibrator(
  truth = truth,
  probability = probability,
  positive = "review"
)
apply_gazepoint_calibrator(
  calibrator,
  probability
)
#>  [1] 0.02561158 0.80708326 0.60546078 0.49085536 0.08201185 0.93429473
#>  [7] 0.71362466 0.27937378 0.19585203 0.88096662 0.37940456 0.60546078
```
