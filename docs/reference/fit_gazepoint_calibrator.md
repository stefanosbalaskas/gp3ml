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

## Value

A fitted `gp3ml_calibrator` object containing the calibration method,
fitted model, and outcome labels.

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
  positive = "review",
  method = "platt"
)
calibrator
#> $method
#> [1] "platt"
#>
#> $fit
#>
#> Call:  stats::glm(formula = y ~ stats::qlogis(p), family = stats::binomial())
#>
#> Coefficients:
#>      (Intercept)  stats::qlogis(p)
#>          -0.4921            2.2699
#>
#> Degrees of Freedom: 11 Total (i.e. Null);  10 Residual
#> Null Deviance:       16.64
#> Residual Deviance: 11.77     AIC: 15.77
#>
#> $positive
#> [1] "review"
#>
#> $negative
#> [1] "pass"
#>
#> attr(,"class")
#> [1] "gp3ml_calibrator"
```
