# Diagnose group-aware Gazepoint resampling folds

Creates fold-size, repeat-level, grouping, assessment-coverage,
outcome-balance, and exclusion diagnostics for an existing
`gazepoint_group_folds` object.

## Usage

``` r
diagnose_gazepoint_group_folds(x, imbalance_review = 1.5, imbalance_fail = 2)
```

## Arguments

- x:

  A `gazepoint_group_folds` object.

- imbalance_review:

  Fold-size ratio above which diagnostics receive a `review` status.

- imbalance_fail:

  Fold-size ratio above which diagnostics receive a `fail` status.

## Value

An object of class `gazepoint_fold_diagnostics`.
