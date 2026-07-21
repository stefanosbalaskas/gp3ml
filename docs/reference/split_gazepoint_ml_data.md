# Create a deterministic group-aware Gazepoint holdout split

Creates analysis and assessment partitions that preserve the grouping
unit implied by an explicit generalization target.

## Usage

``` r
split_gazepoint_ml_data(
  data,
  outcome,
  predictors,
  feature_manifest,
  generalization_target,
  participant_id = NULL,
  trial_id = NULL,
  stimulus_id = NULL,
  assessment_prop = 0.2,
  seed = 1L,
  source_row_id = ".gp3ml_source_row"
)
```

## Arguments

- data:

  Data frame containing the outcome, predictors, and grouping
  identifiers.

- outcome:

  Name of the outcome column.

- predictors:

  Character vector of predictor-column names.

- feature_manifest:

  Feature manifest containing the predictors.

- generalization_target:

  Declared predictive-generalization target.

- participant_id:

  Optional participant-identifier column.

- trial_id:

  Optional trial-identifier column.

- stimulus_id:

  Optional stimulus-identifier column.

- assessment_prop:

  Requested assessment proportion.

- seed:

  Integer random seed.

- source_row_id:

  Name of the source-row identifier added to the returned partitions.

## Value

An object of class `gazepoint_ml_split`.

## Details

For simultaneous participant and stimulus generalization, cross-block
rows are placed in the excluded partition.

This function does not perform preprocessing, feature selection,
resampling, or model fitting.

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
split
#> <gazepoint_ml_split>
#> Target: new_participants
#> Status: PASS
#> Rows: analysis=32, assessment=16, excluded=0
#> Seed: 101
```
