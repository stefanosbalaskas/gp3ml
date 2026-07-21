# Validate outcome, predictor, identifier, and grouping roles

Validate outcome, predictor, identifier, and grouping roles

## Usage

``` r
validate_gazepoint_ml_roles(data, task, predictors, feature_manifest = NULL)
```

## Arguments

- data:

  A data frame containing outcome, predictors, and identifiers.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Character vector naming intended predictors.

- feature_manifest:

  Optional Gazepoint feature-provenance manifest.

## Value

A `gp3ml_role_validation` object containing the overall status, complete
check table, non-passing issues, and optional feature-manifest
validation.

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
manifest <- create_gazepoint_feature_manifest(
  features = c("fixation_duration", "pupil_change"),
  scientific_source = c(
    "Gazepoint fixation export",
    "Gazepoint all-gaze export"
  ),
  source_table = c("fixations", "all_gaze"),
  transformation = c(
    "Trial-level mean",
    "Baseline-adjusted change"
  ),
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = c("none", "resampling_fold"),
  fold_local_required = c(FALSE, TRUE)
)

validate_gazepoint_ml_roles(
  data = example_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  feature_manifest = manifest
)
#> <gp3ml_role_validation> pass
#>                         check status             detail
#>              predictors_exist   pass
#>         outcome_not_predictor   pass
#>    identifiers_not_predictors   pass
#>              outcome_complete   pass                  0
#>       sufficient_group_levels   pass                 12
#>  classification_level_support   pass pass=12, review=12
#>              feature_manifest   pass               pass
```
