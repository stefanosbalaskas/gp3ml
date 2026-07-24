# Nested grouped resampling

## Nested grouped-resampling workflow

``` r

data <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2801L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
outer <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  task$generalization_target,
  "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 1L, seed = 2801L
)
nested <- create_gazepoint_nested_folds(
  outer, inner_v = 2L, inner_repeats = 1L, seed = 2801L
)
nested$audit
#> <gp3ml_nested_resampling_audit> status=pass
#>    outer_fold_id   inner_fold_id status outer_assessment_inner_analysis_overlap
#>  Repeat01_Fold01 Repeat01_Fold01   pass                                       0
#>  Repeat01_Fold01 Repeat01_Fold02   pass                                       0
#>  Repeat01_Fold02 Repeat01_Fold01   pass                                       0
#>  Repeat01_Fold02 Repeat01_Fold02   pass                                       0
#>  Repeat01_Fold03 Repeat01_Fold01   pass                                       0
#>  Repeat01_Fold03 Repeat01_Fold02   pass                                       0
#>  outer_assessment_inner_assessment_overlap
#>                                          0
#>                                          0
#>                                          0
#>                                          0
#>                                          0
#>                                          0
#>  outer_assessment_inner_excluded_overlap inner_analysis_assessment_overlap
#>                                        0                                 0
#>                                        0                                 0
#>                                        0                                 0
#>                                        0                                 0
#>                                        0                                 0
#>                                        0                                 0
#>  inner_analysis_excluded_overlap inner_assessment_excluded_overlap
#>                                0                                 0
#>                                0                                 0
#>                                0                                 0
#>                                0                                 0
#>                                0                                 0
#>                                0                                 0
#>  outer_assessment_overlap
#>                         0
#>                         0
#>                         0
#>                         0
#>                         0
#>                         0
#>                                                       message
#>  No outer-assessment or inner-partition row overlap detected.
#>  No outer-assessment or inner-partition row overlap detected.
#>  No outer-assessment or inner-partition row overlap detected.
#>  No outer-assessment or inner-partition row overlap detected.
#>  No outer-assessment or inner-partition row overlap detected.
#>  No outer-assessment or inner-partition row overlap detected.
```

``` r

grid <- create_gazepoint_tuning_grid(
  "glm",
  preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
  thresholds = 0.5,
  complexity = c(1, 2),
  interpretability = "high"
)
evaluation <- evaluate_gazepoint_nested_resampling(
  nested,
  task,
  grid,
  selection_metric = "brier",
  direction = "minimize",
  predictors = predictors,
  minimum_success_prop = 0.5,
  selection_rationale = "Predeclared Brier-score rule with human review.",
  seed = 2801L
)
evaluation
#> <gp3ml_nested_evaluation>
#>   Target: new_participants
#>   Outer folds: 3
#>   Failed outer folds: 0
#>   Outer assessment predictions: 108
```

Only outer-assessment predictions estimate the declared generalization
target. Inner assessment partitions are used solely for tuning inside
the outer analysis data.
