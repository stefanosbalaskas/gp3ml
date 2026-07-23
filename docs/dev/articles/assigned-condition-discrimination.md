# Experimentally assigned condition discrimination

## Declared task

The label is the experimentally assigned condition. The workflow
assesses whether predeclared measurements discriminate that assignment.
It does not establish psychological interpretation or causal mechanism.

``` r

data <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2201L)
predictors <- c("fixation_duration", "gaze_dispersion", "pupil_change")
task <- create_gazepoint_synthetic_task(
  data, "assigned_condition", "new_participants"
)
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  task$generalization_target,
  task$participant_id, task$unit_id, task$stimulus_id,
  v = 3L, repeats = 1L, seed = 2201L
)
```

## Explicit candidate grid

``` r

grid <- create_gazepoint_tuning_grid(
  engine = "glm",
  preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
  thresholds = c(0.45, 0.55),
  complexity = "low",
  interpretability = "high"
)
tuning <- tune_gazepoint_model(
  folds, task, grid, predictors = predictors, seed = 2201L
)
compare_gazepoint_models(tuning, c("roc_auc", "balanced_accuracy", "brier"))
#>     candidate_id
#> 1  candidate_001
#> 2  candidate_001
#> 3  candidate_001
#> 4  candidate_002
#> 5  candidate_002
#> 6  candidate_002
#> 7  candidate_003
#> 8  candidate_003
#> 9  candidate_003
#> 10 candidate_004
#> 11 candidate_004
#> 12 candidate_004
#>                                                                 label engine
#> 1   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.45]    glm
#> 2   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.45]    glm
#> 3   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.45]    glm
#> 4  glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.45]    glm
#> 5  glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.45]    glm
#> 6  glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.45]    glm
#> 7   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.55]    glm
#> 8   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.55]    glm
#> 9   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.55]    glm
#> 10 glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.55]    glm
#> 11 glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.55]    glm
#> 12 glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.55]    glm
#>    threshold complexity interpretability candidate_status success_prop
#> 1       0.45        low             high             pass            1
#> 2       0.45        low             high             pass            1
#> 3       0.45        low             high             pass            1
#> 4       0.45        low             high             pass            1
#> 5       0.45        low             high             pass            1
#> 6       0.45        low             high             pass            1
#> 7       0.55        low             high             pass            1
#> 8       0.55        low             high             pass            1
#> 9       0.55        low             high             pass            1
#> 10      0.55        low             high             pass            1
#> 11      0.55        low             high             pass            1
#> 12      0.55        low             high             pass            1
#>    failed_folds error            metric      mean         sd n_folds direction
#> 1             0  <NA> balanced_accuracy 0.6574074 0.08929306       3  maximize
#> 2             0  <NA>           roc_auc 0.7345679 0.05136826       3  maximize
#> 3             0  <NA>             brier 0.2239127 0.03635743       3  minimize
#> 4             0  <NA> balanced_accuracy 0.6574074 0.08929306       3  maximize
#> 5             0  <NA>           roc_auc 0.7345679 0.05136826       3  maximize
#> 6             0  <NA>             brier 0.2239127 0.03635743       3  minimize
#> 7             0  <NA> balanced_accuracy 0.6203704 0.05782406       3  maximize
#> 8             0  <NA>           roc_auc 0.7345679 0.05136826       3  maximize
#> 9             0  <NA>             brier 0.2239127 0.03635743       3  minimize
#> 10            0  <NA> balanced_accuracy 0.6203704 0.05782406       3  maximize
#> 11            0  <NA>           roc_auc 0.7345679 0.05136826       3  maximize
#> 12            0  <NA>             brier 0.2239127 0.03635743       3  minimize
```

No candidate is selected automatically. A selection requires an explicit
metric, direction, and human rationale.
