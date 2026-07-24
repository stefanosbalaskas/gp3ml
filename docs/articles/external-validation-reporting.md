# External validation and transportability reporting

## Development workflow

``` r

development <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2901L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(development, "recording_quality", "new_participants")
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  development, task$outcome, predictors, manifest,
  task$generalization_target,
  "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 1L, seed = 2901L
)
development_evaluation <- evaluate_gazepoint_group_folds(
  folds, task, predictors, "glm", seed = 2901L,
  assess_calibration = TRUE, calibration_bootstrap = 0L
)
model <- fit_gazepoint_model(
  development, task, predictors, "glm", seed = 2901L
)
```

## Explicit independent external dataset

``` r

external <- simulate_gazepoint_governed_data(10L, 6L, 1L, seed = 2902L)
external$participant_id <- paste0("E", external$participant_id)
external$trial_id <- paste0("E", external$trial_id)
external$stimulus_id <- paste0("E", external$stimulus_id)
declaration <- declare_gazepoint_external_dataset(
  external,
  label = "synthetic_external_site",
  independent = TRUE,
  origin = "Independent deterministic synthetic generation"
)
report <- evaluate_gazepoint_external_transportability(
  model,
  development_data = development,
  external_data = external,
  declaration = declaration,
  development_evaluation = development_evaluation,
  bootstrap = 0L,
  seed = 2902L
)
report
#> <gp3ml_transportability_report>
#>   Status: externally_validated
#>   Reason: The explicitly independent dataset passed schema and identifier-overlap gates.
#>                       metric development_estimate external_estimate
#>                     accuracy           0.87037037         0.8833333
#>            balanced_accuracy           0.49425287         0.5000000
#>                  sensitivity           0.00000000         0.0000000
#>                  specificity           0.98850575         1.0000000
#>                    precision           0.00000000                NA
#>                       recall           0.00000000         0.0000000
#>                           f1                  NaN                NA
#>                          mcc          -0.08304548                NA
#>                      roc_auc           0.57340641         0.7277628
#>                       pr_auc           0.30964591         0.3291055
#>                        brier           0.11055175         0.0956074
#>                     log_loss           0.39533485         0.3260348
#>                          ece           0.11646202                NA
#>    calibration_intercept_abs           3.23095109                NA
#>  calibration_slope_abs_error           1.47811645                NA
#>    difference
#>   0.012962963
#>   0.005747126
#>   0.000000000
#>   0.011494253
#>            NA
#>   0.000000000
#>            NA
#>            NA
#>   0.154356393
#>   0.019459639
#>  -0.014944353
#>  -0.069300020
#>            NA
#>            NA
#>            NA
report$performance_comparison
#>                         metric development_estimate external_estimate
#> 1                     accuracy           0.87037037         0.8833333
#> 2            balanced_accuracy           0.49425287         0.5000000
#> 3                  sensitivity           0.00000000         0.0000000
#> 4                  specificity           0.98850575         1.0000000
#> 5                    precision           0.00000000                NA
#> 6                       recall           0.00000000         0.0000000
#> 7                           f1                  NaN                NA
#> 8                          mcc          -0.08304548                NA
#> 9                      roc_auc           0.57340641         0.7277628
#> 10                      pr_auc           0.30964591         0.3291055
#> 11                       brier           0.11055175         0.0956074
#> 12                    log_loss           0.39533485         0.3260348
#> 13                         ece           0.11646202                NA
#> 14   calibration_intercept_abs           3.23095109                NA
#> 15 calibration_slope_abs_error           1.47811645                NA
#>      difference
#> 1   0.012962963
#> 2   0.005747126
#> 3   0.000000000
#> 4   0.011494253
#> 5            NA
#> 6   0.000000000
#> 7            NA
#> 8            NA
#> 9   0.154356393
#> 10  0.019459639
#> 11 -0.014944353
#> 12 -0.069300020
#> 13           NA
#> 14           NA
#> 15           NA
report$group_coverage
#>          unit     identifier development_groups external_groups
#> 1 participant participant_id                 18              10
#> 2    stimulus    stimulus_id                  6               6
#>   overlapping_groups external_novel_groups external_coverage_prop status
#> 1                  0                    10                      1   pass
#> 2                  0                     6                      1   pass
```

## Explicit absence of external validation

``` r

not_validated <- evaluate_gazepoint_external_transportability(
  model,
  development_data = development,
  external_data = NULL
)
not_validated
#> <gp3ml_transportability_report>
#>   Status: not_externally_validated
#>   Reason: No independent external dataset was supplied.
```

An internal holdout is never renamed external validation. The external
result is specific to the declared dataset and context.
