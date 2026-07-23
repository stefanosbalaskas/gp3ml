# Apply a fitted preprocessing engine

Apply a fitted preprocessing engine

## Usage

``` r
bake_gazepoint_preprocessor(preprocessor, new_data)
```

## Arguments

- preprocessor:

  A fitted `gp3ml_preprocessor` object.

- new_data:

  Data to transform using the fitted parameters.

## Value

A numeric model matrix transformed using only the parameters stored in
the fitted preprocessor.

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
baked <- bake_gazepoint_preprocessor(
  preprocessor,
  example_data
)
dim(baked)
#> [1] 24  4
```
