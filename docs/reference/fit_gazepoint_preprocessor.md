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

## Value

A fitted `gp3ml_preprocessor` object containing analysis-partition
imputation values, factor levels, model columns, centering values, and
scaling values.

## Examples

``` r
example_data <- data.frame(
  participant_id = rep(sprintf("P%02d", 1:12), each = 2),
  trial_id = sprintf("T%02d", 1:24),
  stimulus_id = rep(c("S01", "S02"), 12),
  condition = rep(c("A", "B"), 12),
  fixation_duration = 180 + seq_len(24),
  pupil_change = sin(seq_len(24) / 3),
  stringsAsFactors = FALSE
)
example_data$quality_status <- factor(
  c(
    "pass", "review", "pass", "review", "review", "pass",
    "review", "pass", "pass", "review", "review", "pass",
    "review", "pass", "review", "pass", "pass", "review",
    "pass", "review", "review", "pass", "pass", "review"
  ),
  levels = c("pass", "review")
)
preprocessor <- fit_gazepoint_preprocessor(
  data = example_data,
  predictors = c(
    "fixation_duration",
    "pupil_change",
    "condition"
  )
)
preprocessor
#> <gp3ml_preprocessor> 3 raw predictors -> 4 model columns
```
