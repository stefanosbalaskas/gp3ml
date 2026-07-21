# Create deterministic group-aware Gazepoint resampling folds

Creates repeated grouped assessment folds that preserve the grouping
structure implied by an explicit generalization target. A passing
feature-provenance manifest is required, and every analysis-assessment
pair is evaluated using the leakage audit.

## Usage

``` r
create_gazepoint_group_folds(
  data,
  outcome,
  predictors,
  feature_manifest,
  generalization_target,
  participant_id = NULL,
  trial_id = NULL,
  stimulus_id = NULL,
  v = 5L,
  repeats = 1L,
  seed = 1L,
  source_row_id = ".gp3ml_source_row"
)
```

## Arguments

- data:

  A data frame containing the outcome, predictors, and grouping
  identifiers.

- outcome:

  Name of the outcome column.

- predictors:

  Character vector naming intended predictors.

- feature_manifest:

  A feature manifest containing all intended predictors.

- generalization_target:

  One of `"new_trials_known_participants"`, `"new_participants"`,
  `"new_stimuli"`, or `"new_participants_and_new_stimuli"`.

- participant_id:

  Optional participant-identifier column.

- trial_id:

  Optional trial-identifier column.

- stimulus_id:

  Optional stimulus-identifier column.

- v:

  Number of group folds. For simultaneous participant and stimulus
  generalization, a length-two vector specifies participant and stimulus
  fold counts.

- repeats:

  Number of repeated fold assignments.

- seed:

  Integer random seed. The caller's random-number state is restored.

- source_row_id:

  Name of the source-row identifier added to returned partitions.

## Value

An object of class `gazepoint_group_folds`.

## Details

For new trials among known participants, participant-trial units are
assigned separately within each participant. For simultaneous
participant and stimulus generalization, crossed participant-stimulus
assessment blocks are created; cross-block rows are excluded from that
fold. Each source row appears in assessment exactly once per repeat.

This function does not perform preprocessing, feature selection, tuning,
nested resampling, or model fitting.

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
folds
#> <gazepoint_group_folds>
#> Target: new_participants
#> Repeats: 1
#> Folds per repeat: 3
#> Total folds: 3
#> Status: PASS
```
