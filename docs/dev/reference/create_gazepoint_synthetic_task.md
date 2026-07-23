# Create one of the governed synthetic demonstration tasks

Create one of the governed synthetic demonstration tasks

## Usage

``` r
create_gazepoint_synthetic_task(
  data,
  workflow = c("recording_quality", "assigned_condition", "observed_behavior",
    "observed_duration"),
  generalization_target = c("new_trials_known_participants", "new_participants",
    "new_stimuli", "new_participants_and_new_stimuli")
)
```

## Arguments

- data:

  Synthetic data from
  [`simulate_gazepoint_governed_data()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/simulate_gazepoint_governed_data.md).

- workflow:

  Workflow name.

- generalization_target:

  Declared generalization target.

## Value

A governed `gp3ml_task`.

## Examples

``` r
synthetic <- simulate_gazepoint_governed_data(12L, 4L, 1L, 101L)
create_gazepoint_synthetic_task(
  synthetic,
  workflow = "recording_quality",
  generalization_target = "new_participants"
)
#> <gp3ml_task>
#>   type: classification
#>   outcome: quality_status
#>   target: new_participants
#>   purpose: Predict predefined recording-quality review status
```
