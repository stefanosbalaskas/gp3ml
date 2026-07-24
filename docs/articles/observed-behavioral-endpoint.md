# Explicitly observed behavioural endpoint

## Observed endpoint

``` r

data <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2301L)
predictors <- c("tracking_ratio", "fixation_duration", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(
  data, "observed_behavior", "new_participants"
)
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  task$generalization_target,
  task$participant_id, task$unit_id, task$stimulus_id,
  v = 3L, repeats = 2L, seed = 2301L
)
```

## Evaluate and quantify participant-cluster uncertainty

``` r

evaluation <- evaluate_gazepoint_group_folds(
  folds, task, predictors, "glm", seed = 2301L
)
predictions <- evaluation$predictions
uncertainty <- bootstrap_gazepoint_metrics_by_unit(
  task,
  truth = predictions$truth,
  prediction = factor(
    predictions$prediction,
    levels = levels(data$observed_response)
  ),
  probability = predictions$probability,
  participant_id = predictions$participant_id,
  unit = "participant",
  bootstrap = 50L,
  seed = 2301L
)
uncertainty
#> <gp3ml_target_uncertainty>
#>   Unit: participant
#>   Target: new_participants
#>   Successful/failed replicates: 50/0
#>             metric    estimate      lower     upper successful_replicates
#>           accuracy 0.541666667  0.4547454 0.5961806                    50
#>  balanced_accuracy 0.502703174  0.4348836 0.5700013                    50
#>        sensitivity 0.202127660  0.1169271 0.3006962                    50
#>        specificity 0.803278689  0.6919828 0.9101786                    50
#>          precision 0.441860465  0.2843813 0.6902406                    50
#>             recall 0.202127660  0.1169271 0.3006962                    50
#>                 f1 0.277372263  0.1800560 0.3836667                    50
#>                mcc 0.006712597 -0.1529414 0.1867860                    50
#>            roc_auc 0.511248692  0.4412685 0.6007832                    50
#>             pr_auc 0.453755329  0.3649841 0.5836588                    50
#>              brier 0.254567555  0.2413744 0.2722628                    50
#>           log_loss 0.704706896  0.6760984 0.7414688                    50
```

The endpoint is the recorded response only. The analysis does not infer
intent, comprehension, cognition, or another latent construct.
