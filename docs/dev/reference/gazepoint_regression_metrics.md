# Regression metrics

Regression metrics

## Usage

``` r
gazepoint_regression_metrics(truth, prediction)
```

## Arguments

- truth:

  Observed numeric outcome values.

- prediction:

  Predicted numeric outcome values.

## Value

A one-row data frame containing the sample size, RMSE, MAE, R-squared
value, and prediction correlation.

## Examples

``` r
truth <- c(1.0, 2.0, 3.0, 4.0, 5.0)
prediction <- c(1.1, 1.8, 3.2, 3.9, 4.8)
gazepoint_regression_metrics(truth, prediction)
#>   n     rmse  mae r_squared correlation
#> 1 5 0.167332 0.16     0.986   0.9941242
```
