# Summarize uncertainty across folds or repeats

Summarize uncertainty across folds or repeats

## Usage

``` r
summarize_gazepoint_resample_uncertainty(
  evaluation,
  unit = c("fold", "repeat"),
  conf_level = 0.95
)

# S3 method for class 'gp3ml_resample_uncertainty'
print(x, ...)
```

## Arguments

- evaluation:

  A `gp3ml_resample_evaluation` or `gp3ml_nested_evaluation`.

- unit:

  Distribution unit: individual folds or repeat means.

- conf_level:

  Quantile interval level.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_resample_uncertainty` object.
