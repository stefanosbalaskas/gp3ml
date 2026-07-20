# Fit a fold-local preprocessing engine

Fit a fold-local preprocessing engine

## Usage

``` r
fit_gazepoint_preprocessor(
  data,
  predictors,
  numeric_imputation = c("median", "mean"),
  center = TRUE,
  scale = TRUE,
  novel_level = c("other", "error"),
  remove_zero_variance = TRUE
)
```

## Arguments

- data:

  Analysis data used to estimate preprocessing parameters.

- predictors:

  Character vector naming predictor columns.

- numeric_imputation:

  Numeric imputation method.

- center:

  Whether numeric model columns should be centered.

- scale:

  Whether numeric model columns should be scaled.

- novel_level:

  How novel categorical levels should be handled.

- remove_zero_variance:

  Whether zero-variance columns are removed.
