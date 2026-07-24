# Compare governed model candidates without selecting a winner

Compare governed model candidates without selecting a winner

## Usage

``` r
compare_gazepoint_models(x, metrics = NULL)
```

## Arguments

- x:

  A `gp3ml_model_tuning` object.

- metrics:

  Optional metric names.

## Value

A data frame retaining candidate status, failures, complexity,
interpretability, and fold-distribution summaries.
