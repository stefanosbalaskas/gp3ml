# Simultaneous participant and stimulus generalization

## Participant-and-stimulus generalization workflow

``` r

data <- simulate_gazepoint_governed_data(18L, 6L, 1L, seed = 2601L)
predictors <- c("tracking_ratio", "blink_rate", "gaze_dispersion")
task <- create_gazepoint_synthetic_task(
  data, "recording_quality", "new_participants_and_new_stimuli"
)
manifest <- create_gazepoint_synthetic_manifest(task$outcome, predictors)
folds <- create_gazepoint_group_folds(
  data, task$outcome, predictors, manifest,
  task$generalization_target,
  "participant_id", "trial_id", "stimulus_id",
  v = 3L, repeats = 1L, seed = 2601L
)
folds$fold_summary
#>   repeat fold          fold_id participant_fold stimulus_fold n_total
#> 1      1    1 Repeat01_P01_S01                1             1     108
#> 2      1    2 Repeat01_P02_S01                2             1     108
#> 3      1    3 Repeat01_P03_S01                3             1     108
#> 4      1    4 Repeat01_P01_S02                1             2     108
#> 5      1    5 Repeat01_P02_S02                2             2     108
#> 6      1    6 Repeat01_P03_S02                3             2     108
#> 7      1    7 Repeat01_P01_S03                1             3     108
#> 8      1    8 Repeat01_P02_S03                2             3     108
#> 9      1    9 Repeat01_P03_S03                3             3     108
#>   n_analysis n_assessment n_excluded assessment_prop_all
#> 1         48           12         48           0.1111111
#> 2         48           12         48           0.1111111
#> 3         48           12         48           0.1111111
#> 4         48           12         48           0.1111111
#> 5         48           12         48           0.1111111
#> 6         48           12         48           0.1111111
#> 7         48           12         48           0.1111111
#> 8         48           12         48           0.1111111
#> 9         48           12         48           0.1111111
#>   assessment_prop_retained leakage_status
#> 1                      0.2           pass
#> 2                      0.2           pass
#> 3                      0.2           pass
#> 4                      0.2           pass
#> 5                      0.2           pass
#> 6                      0.2           pass
#> 7                      0.2           pass
#> 8                      0.2           pass
#> 9                      0.2           pass
evaluation <- evaluate_gazepoint_group_folds(
  folds, task, predictors, "glm", seed = 2601L
)
evaluation$fold_status
#>   repeat fold          fold_id status leakage_status n_analysis n_assessment
#> 1      1    1 Repeat01_P01_S01 review           pass         48           12
#> 2      1    2 Repeat01_P02_S01 review           pass         48           12
#> 3      1    3 Repeat01_P03_S01 review           pass         48           12
#> 4      1    4 Repeat01_P01_S02 review           pass         48           12
#> 5      1    5 Repeat01_P02_S02 review           pass         48           12
#> 6      1    6 Repeat01_P03_S02   fail           pass         48           12
#> 7      1    7 Repeat01_P01_S03 review           pass         48           12
#> 8      1    8 Repeat01_P02_S03 review           pass         48           12
#> 9      1    9 Repeat01_P03_S03 review           pass         48           12
#>   n_excluded n_predictions n_missing_predictions warning_count
#> 1         48            12                     0             1
#> 2         48            12                     0             1
#> 3         48            12                     0             1
#> 4         48            12                     0             1
#> 5         48            12                     0             1
#> 6         48             0                    12             1
#> 7         48            12                     0             1
#> 8         48            12                     0             1
#> 9         48            12                     0             1
#>                                              error
#> 1                                             <NA>
#> 2                                             <NA>
#> 3                                             <NA>
#> 4                                             <NA>
#> 5                                             <NA>
#> 6 Binary metrics require exactly two truth levels.
#> 7                                             <NA>
#> 8                                             <NA>
#> 9                                             <NA>
#>                          warnings
#> 1 'drop' argument will be ignored
#> 2 'drop' argument will be ignored
#> 3 'drop' argument will be ignored
#> 4 'drop' argument will be ignored
#> 5 'drop' argument will be ignored
#> 6 'drop' argument will be ignored
#> 7 'drop' argument will be ignored
#> 8 'drop' argument will be ignored
#> 9 'drop' argument will be ignored
head(evaluation$excluded)
#>   participant_id trial_id stimulus_id replicate assigned_condition
#> 1           P001   T00001        S001         1                  A
#> 2           P001   T00003        S003         1                  A
#> 3           P001   T00005        S005         1                  A
#> 4           P001   T00006        S006         1                  B
#> 5           P002   T00008        S002         1                  A
#> 6           P002   T00010        S004         1                  A
#>   tracking_ratio blink_rate fixation_duration gaze_dispersion pupil_change
#> 1      0.9273132   5.294479          219.2280       0.7314324  -0.22127869
#> 2      0.9587020   5.804824          215.6037       0.5876004   0.09574297
#> 3      0.8958902   5.473938          162.7716       0.4723956  -0.17907113
#> 4      0.9151056   6.575351          220.7356       0.5047154   0.01752138
#> 5      0.9045578   5.841082          200.0662       0.7875270  -0.33577902
#> 6      0.9226943   6.528077          194.3891       0.5889301   0.07204087
#>   quality_status observed_response observed_duration       site_label
#> 1           pass       recorded_no          5.693151 development_site
#> 2           pass      recorded_yes          8.098351 development_site
#> 3           pass      recorded_yes          6.851908    external_site
#> 4           pass       recorded_no          6.279029    external_site
#> 5           pass       recorded_no          5.918344 development_site
#> 6           pass       recorded_no          7.784713    external_site
#>   .gp3ml_source_row repeat fold          fold_id
#> 1                 1      1    1 Repeat01_P01_S01
#> 2                 3      1    1 Repeat01_P01_S01
#> 3                 5      1    1 Repeat01_P01_S01
#> 4                 6      1    1 Repeat01_P01_S01
#> 5                 8      1    1 Repeat01_P01_S01
#> 6                10      1    1 Repeat01_P01_S01
```

Cross-block rows that belong to only one held-out grouping dimension
remain explicitly excluded. They are not silently reassigned to analysis
or assessment.
