# Print group-aware split validation

Print group-aware split validation

## Usage

``` r
# S3 method for class 'gazepoint_ml_split_validation'
print(x, ...)
```

## Arguments

- x:

  An object returned by
  [`validate_gazepoint_ml_split()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_ml_split.md).

- ...:

  Additional arguments, currently unused.

## Value

`x`, invisibly.

## Examples

``` r
example_data <- expand.grid(
  participant_id = sprintf("P%02d", 1:6),
  stimulus_id = sprintf("S%02d", 1:4),
  repetition = 1:2,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
example_data$trial_id <- paste0(
  example_data$stimulus_id,
  "_T",
  example_data$repetition
)
participant_number <- as.integer(
  sub("P", "", example_data$participant_id)
)
stimulus_number <- as.integer(
  sub("S", "", example_data$stimulus_id)
)
example_data$outcome <- factor(
  ifelse(
    (participant_number + stimulus_number) %% 2L == 0L,
    "review",
    "pass"
  ),
  levels = c("pass", "review")
)
row_index <- seq_len(nrow(example_data))
example_data$fixation_duration <- 180 + row_index
example_data$pupil_change <- round(
  sin(row_index / 7),
  4
)
example_data$repetition <- NULL
manifest <- create_gazepoint_feature_manifest(
  features = c("fixation_duration", "pupil_change"),
  scientific_source = c(
    "Gazepoint fixation export",
    "Gazepoint pupil export"
  ),
  source_table = c("fixations", "pupil"),
  transformation = c(
    "Trial-level mean",
    "Trial-level change"
  ),
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = "none",
  fold_local_required = FALSE
)
split <- split_gazepoint_ml_data(
  data = example_data,
  outcome = "outcome",
  predictors = c("fixation_duration", "pupil_change"),
  feature_manifest = manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  assessment_prop = 1 / 3,
  seed = 101L
)
validation <- validate_gazepoint_ml_split(split)
print(validation)
#> <gazepoint_ml_split_validation>
#> Overall status: PASS
#> Non-passing checks: 0
#>  status n_checks
#>  pass   8
#>  review 0
#>  fail   0
```
