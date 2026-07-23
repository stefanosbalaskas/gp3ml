# Collect predictions from a grouped-fold evaluation

Collect predictions from a grouped-fold evaluation

## Usage

``` r
collect_gazepoint_fold_predictions(x, include_failed = TRUE)
```

## Arguments

- x:

  A `gp3ml_resample_evaluation`.

- include_failed:

  Whether failed folds are represented by explicit status rows when they
  produced no predictions.

## Value

A data frame of row-level assessment predictions with fold labels.
