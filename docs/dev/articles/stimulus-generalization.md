# Stimulus generalization

## Stimulus-grouped generalization workflow

``` r

data <- simulate_gazepoint_governed_data(18L, 9L, 1L, seed = 2501L)
predictors <- c("tracking_ratio", "fixation_duration", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_stimuli")
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  "new_stimuli", "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 2L, seed = 2501L
)
diagnose_gazepoint_group_folds(folds)
#> <gazepoint_fold_diagnostics>
#> Target: new_stimuli
#> Repeats: 2
#> Folds: 6
#> Outcome type: categorical
#> Diagnostic status: PASS
#> Maximum assessment-size ratio: 1.000
evaluation <- evaluate_gazepoint_group_folds(
  folds, task, predictors, "glm", seed = 2501L
)
summarize_gazepoint_resample_uncertainty(evaluation, unit = "fold")
#> <gp3ml_resample_uncertainty> unit=fold
#>             metric distribution_unit n_units      mean    median         sd
#>           accuracy              fold       6 0.8209877 0.8333333 0.03447961
#>  balanced_accuracy              fold       6 0.5000000 0.5000000 0.00000000
#>        sensitivity              fold       6 0.0000000 0.0000000 0.00000000
#>        specificity              fold       6 1.0000000 1.0000000 0.00000000
#>          precision              fold       0       NaN        NA         NA
#>             recall              fold       6 0.0000000 0.0000000 0.00000000
#>                 f1              fold       0       NaN        NA         NA
#>                mcc              fold       0       NaN        NA         NA
#>            roc_auc              fold       6 0.5983918 0.5692935 0.06668780
#>             pr_auc              fold       6 0.2693216 0.2921778 0.06735544
#>              brier              fold       6 0.1475925 0.1350173 0.02302486
#>           log_loss              fold       6 0.4728527 0.4385498 0.06276389
#>      lower     upper
#>  0.7777778 0.8518519
#>  0.5000000 0.5000000
#>  0.0000000 0.0000000
#>  1.0000000 1.0000000
#>         NA        NA
#>  0.0000000 0.0000000
#>         NA        NA
#>         NA        NA
#>  0.5411706 0.6959877
#>  0.1849514 0.3319524
#>  0.1284306 0.1778630
#>  0.4217248 0.5576091
```

Stimulus-grouped assessment estimates generalization to held-out stimuli
only. It does not establish participant generalization.
