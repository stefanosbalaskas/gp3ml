# Summarize repeated grouped-resampling performance

Summarize repeated grouped-resampling performance

## Usage

``` r
summarize_gazepoint_resample_performance(
  x,
  aggregation = c("fold_distribution", "pooled_rows"),
  conf_level = 0.95
)

# S3 method for class 'gp3ml_resample_performance_summary'
print(x, ...)
```

## Arguments

- x:

  A `gp3ml_resample_evaluation`.

- aggregation:

  Either fold-distribution summaries or pooled row-level predictions.
  Pooled rows are explicitly labelled and do not change the
  generalization unit.

- conf_level:

  Confidence level for fold-distribution quantiles.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_resample_performance_summary` object.
