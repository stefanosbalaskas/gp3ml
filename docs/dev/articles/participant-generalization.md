# Participant generalization

## Participant-grouped generalization workflow

``` r

data <- simulate_gazepoint_governed_data(21L, 6L, 1L, seed = 2401L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  "new_participants", "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 2L, seed = 2401L
)
audit_gazepoint_group_folds(folds)
#> <gazepoint_group_folds_audit>
#> Overall status: PASS
#> Audited folds: 6
#> Non-passing checks: 0
evaluation <- evaluate_gazepoint_group_folds(
  folds, task, predictors, "glm", seed = 2401L
)
summary <- summarize_gazepoint_resample_performance(evaluation)
summary
#> <gp3ml_resample_performance_summary>
#>   Aggregation: fold_distribution
#>   Generalization target: new_participants
#>             metric direction n_folds      mean    median         sd      lower
#>           accuracy  maximize       6 0.8571429 0.8690476 0.04259177 0.79166667
#>  balanced_accuracy  maximize       6 0.5000000 0.5000000 0.00000000 0.50000000
#>        sensitivity  maximize       6 0.0000000 0.0000000 0.00000000 0.00000000
#>        specificity  maximize       6 1.0000000 1.0000000 0.00000000 1.00000000
#>          precision  maximize       0       NaN        NA         NA         NA
#>             recall  maximize       6 0.0000000 0.0000000 0.00000000 0.00000000
#>                 f1  maximize       0       NaN        NA         NA         NA
#>                mcc  maximize       0       NaN        NA         NA         NA
#>            roc_auc  maximize       6 0.4052153 0.3968185 0.08924391 0.30115115
#>             pr_auc  maximize       6 0.1469220 0.1568414 0.03149465 0.10381845
#>              brier  minimize       6 0.1324497 0.1266883 0.03713214 0.09352752
#>           log_loss  minimize       6 0.4539622 0.4347007 0.11777270 0.34000404
#>      upper
#>  0.9017857
#>  0.5000000
#>  0.0000000
#>  1.0000000
#>         NA
#>  0.0000000
#>         NA
#>         NA
#>  0.5155805
#>  0.1786388
#>  0.1902474
#>  0.6431489
```

Every participant is assigned as a group. Row-level assessment metrics
describe predictions under this grouped design; they are not
participant-level measurements.
