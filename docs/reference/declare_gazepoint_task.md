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

## Value

A governed `gp3ml_task` object describing the outcome, scientific
purpose, prediction unit, grouping roles, task type, and generalization
target.

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
task <- declare_gazepoint_task(
  data = example_data,
  outcome = "quality_status",
  purpose = "Predict predefined recording-quality review status",
  task_type = "classification",
  unit_id = "trial_id",
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants",
  positive = "review"
)
task
#> <gp3ml_task>
#>   type: classification
#>   outcome: quality_status
#>   target: new_participants
#>   purpose: Predict predefined recording-quality review status
```
