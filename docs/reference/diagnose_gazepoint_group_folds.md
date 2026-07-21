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
folds <- create_gazepoint_group_folds(
  data = example_data,
  outcome = "outcome",
  predictors = c("fixation_duration", "pupil_change"),
  feature_manifest = manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  v = 3L,
  repeats = 1L,
  seed = 101L
)
diagnostics <- diagnose_gazepoint_group_folds(folds)
diagnostics
#> <gazepoint_fold_diagnostics>
#> Target: new_participants
#> Repeats: 1
#> Folds: 3
#> Outcome type: categorical
#> Diagnostic status: PASS
#> Maximum assessment-size ratio: 1.000
```
