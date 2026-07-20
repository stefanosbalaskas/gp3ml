# Declare a governed Gazepoint prediction task

Declare a governed Gazepoint prediction task

## Usage

``` r
declare_gazepoint_task(
  data,
  outcome,
  purpose,
  task_type = c("classification", "regression"),
  unit_id,
  participant_id = NULL,
  stimulus_id = NULL,
  generalization_target = c("new_trials_known_participants", "new_participants",
    "new_stimuli", "new_participants_and_new_stimuli", "external_validation"),
  positive = NULL,
  observed_outcome = TRUE,
  sensitive_outcome = FALSE
)
```

## Arguments

- data:

  A data frame containing the outcome and task identifiers.

- outcome:

  Name of the explicitly observed outcome column.

- purpose:

  One explicit scientific-purpose statement.

- task_type:

  Either `classification` or `regression`.

- unit_id:

  Column identifying the prediction unit.

- participant_id:

  Optional participant-identifier column.

- stimulus_id:

  Optional stimulus-identifier column.

- generalization_target:

  The intended target of generalization.

- positive:

  Positive outcome level for binary classification.

- observed_outcome:

  Whether the outcome was directly observed.

- sensitive_outcome:

  Whether the outcome is sensitive or prohibited.
