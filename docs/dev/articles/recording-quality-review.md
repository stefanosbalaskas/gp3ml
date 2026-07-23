# Predefined recording-quality review status

## Scope

This workflow predicts a **predefined recording-quality review status**.
It does not infer health, emotion, cognition, intent, identity, or any
latent state. Predictions support manual quality review.

``` r

data <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2101L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(
  data, "recording_quality", "new_participants"
)
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
```

## Materialized grouped folds

``` r

folds <- create_gazepoint_group_folds(
  data = data,
  outcome = task$outcome,
  predictors = predictors,
  feature_manifest = manifest,
  generalization_target = task$generalization_target,
  participant_id = task$participant_id,
  trial_id = task$unit_id,
  stimulus_id = task$stimulus_id,
  v = 3L,
  repeats = 2L,
  seed = 2101L
)
folds$validation
#> <gazepoint_group_folds_validation>
#> Overall status: PASS
#> Non-passing checks: 0
#>  status n_checks
#>  pass   10
#>  review  0
#>  fail    0
```

## Fold-local evaluation

``` r

evaluation <- evaluate_gazepoint_group_folds(
  folds,
  task,
  predictors = predictors,
  engine = "glm",
  seed = 2101L,
  assess_calibration = TRUE,
  calibration_bootstrap = 0L
)
evaluation
#> <gp3ml_resample_evaluation>
#>   Target: new_participants
#>   Engine: glm
#>   Folds: 6
#>   Passed/review/failed: 0/6/0
#>   Predictions: 216
summarize_gazepoint_resample_performance(evaluation)
#> <gp3ml_resample_performance_summary>
#>   Aggregation: fold_distribution
#>   Generalization target: new_participants
#>                       metric direction n_folds       mean     median         sd
#>                     accuracy  maximize       6 0.84259259 0.86111111 0.04182070
#>            balanced_accuracy  maximize       6 0.50000000 0.50000000 0.00000000
#>                  sensitivity  maximize       6 0.00000000 0.00000000 0.00000000
#>                  specificity  maximize       6 1.00000000 1.00000000 0.00000000
#>                    precision  maximize       0        NaN         NA         NA
#>                       recall  maximize       6 0.00000000 0.00000000 0.00000000
#>                           f1  maximize       0        NaN         NA         NA
#>                          mcc  maximize       0        NaN         NA         NA
#>                      roc_auc  maximize       6 0.53467026 0.54503168 0.11547975
#>                       pr_auc  maximize       6 0.24900373 0.23918425 0.10870279
#>                        brier  minimize       6 0.13788835 0.12682092 0.02669985
#>                     log_loss  minimize       6 0.46057506 0.44401108 0.07542136
#>                          ece  minimize       6 0.08702245 0.09329012 0.02939006
#>    calibration_intercept_abs  minimize       6 2.03128737 2.06036453 1.06758980
#>  calibration_slope_abs_error  minimize       6 1.17034109 1.05761065 0.44551677
#>       lower     upper
#>  0.78125000 0.8854167
#>  0.50000000 0.5000000
#>  0.00000000 0.0000000
#>  1.00000000 1.0000000
#>          NA        NA
#>  0.00000000 0.0000000
#>          NA        NA
#>          NA        NA
#>  0.37693422 0.6730534
#>  0.11783989 0.4064157
#>  0.11687549 0.1810071
#>  0.39512104 0.5826945
#>  0.05100565 0.1148373
#>  0.64841519 3.4189402
#>  0.64316656 1.8327136
```

## Interpretation

The metrics describe assessment-row predictions generated under
participant-grouped resampling. They must not be relabelled as
participant-level outcomes.
