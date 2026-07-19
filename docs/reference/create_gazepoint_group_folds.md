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
