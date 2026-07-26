# Integrated Synthetic Gazepoint Research Workflow

## Synthetic upstream outputs

This article represents prepared outputs from `gp3tools`,
`gpbiometrics`, and `gp3sequences`. The values are synthetic and
shareable. The outcome is an experimentally assigned condition; the
workflow does not infer emotion, stress, cognition, health, identity,
intent, or another prohibited construct.

``` r

bundle <- simulate_gazepoint_research_handoffs(
  n_participants = 18L,
  n_stimuli = 4L,
  seed = 3401L
)
validation <- validate_gazepoint_research_bundle(bundle)
validation
#>  gp3ml research bundle validation: pass
#>                                check status
#>             required_sources_present   pass
#>                    all_handoffs_pass   pass
#>                combined_rows_present   pass
#>             assigned_outcome_present   pass
#>      no_prohibited_inference_columns   pass
#>  participant_generalization_declared   pass
#>                                detail
#>  gp3tools, gpbiometrics, gp3sequences
#>                  3/3 handoffs passed.
#>                     72 combined rows.
#>                    assigned_condition
#>                        None detected.
#>                      new_participants
plot(validation)
```

![](integrated-research-workflow_files/figure-html/bundle-1.png)

## Assemble the modelling handoff

``` r

combined <- validation$bundle
data <- as_gp3ml_data(combined)

predictors <- c(
  "valid_gaze_prop",
  "fixation_count",
  "mean_fixation_ms",
  "gaze_dispersion",
  "eda_valid_prop",
  "hr_valid_prop",
  "ibi_valid_prop",
  "sequence_length",
  "unique_state_count",
  "transition_rate"
)
```

## Declare task and provenance

``` r

task <- declare_gazepoint_task(
  data = data,
  outcome = "assigned_condition",
  purpose = "Discriminate an experimentally assigned condition using predeclared observed non-sensitive Gazepoint-derived predictors",
  task_type = "classification",
  unit_id = "trial_id",
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants",
  positive = "B",
  observed_outcome = TRUE,
  sensitive_outcome = FALSE
)

manifest <- create_gazepoint_feature_manifest(
  features = predictors,
  scientific_source = c(
    rep("gp3tools prepared gaze/fixation summaries", 4L),
    rep("gpbiometrics prepared signal-quality summaries", 3L),
    rep("gp3sequences prepared sequence summaries", 3L)
  ),
  source_table = c(
    rep("gp3tools handoff", 4L),
    rep("gpbiometrics handoff", 3L),
    rep("gp3sequences handoff", 3L)
  ),
  transformation = "Prepared upstream summary passed through a validated interoperability handoff",
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  outcome_derived = FALSE,
  post_outcome = FALSE,
  identifier = FALSE,
  preprocessing_scope = "none",
  fold_local_required = FALSE,
  reviewer_notes = "Synthetic shareable cross-package validation workflow."
)

validate_gazepoint_feature_manifest(manifest)
#> <gazepoint_feature_manifest_validation>
#> Overall status: PASS
#> Features: 10
#> Non-passing checks: 0
#>  status n_checks
#>  pass   110     
#>  review   0     
#>  fail     0
```

## Participant-grouped resampling

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
  repeats = 1L,
  seed = 3401L
)

validate_gazepoint_group_folds(folds)
#> <gazepoint_group_folds_validation>
#> Overall status: PASS
#> Non-passing checks: 0
#>  status n_checks
#>  pass   10      
#>  review  0      
#>  fail    0
audit_gazepoint_group_folds(folds)
#> <gazepoint_group_folds_audit>
#> Overall status: PASS
#> Audited folds: 3
#> Non-passing checks: 0
```

## Repository-aware evaluation when available

``` r

if ("evaluate_gazepoint_group_folds" %in% getNamespaceExports("gp3ml")) {
  evaluation <- evaluate_gazepoint_group_folds(
    folds,
    task,
    predictors,
    "glm",
    seed = 3401L
  )
  validate_gazepoint_resample_evaluation(evaluation)
  summarize_gazepoint_resample_performance(evaluation)
} else {
  diagnostics <- diagnose_gazepoint_group_folds(folds)
  validate_gazepoint_fold_diagnostics(diagnostics)
}
#> <gp3ml_resample_performance_summary>
#>   Aggregation: fold_distribution
#>   Generalization target: new_participants
#>             metric direction n_folds      mean    median         sd      lower
#>           accuracy  maximize       3 0.5694444 0.5833333 0.10485881 0.46458333
#>  balanced_accuracy  maximize       3 0.5972222 0.5937500 0.06777507 0.53437500
#>        sensitivity  maximize       3 0.5763889 0.5625000 0.16710013 0.42395833
#>        specificity  maximize       3 0.6180556 0.6250000 0.30214319 0.32812500
#>          precision  maximize       3 0.6454248 0.7500000 0.25670241 0.37279412
#>             recall  maximize       3 0.5763889 0.5625000 0.16710013 0.42395833
#>                 f1  maximize       3 0.5594709 0.5555556 0.08149914 0.48377778
#>                mcc  maximize       3 0.2088324 0.1767767 0.16242982 0.07041819
#>            roc_auc  maximize       3 0.6493056 0.6562500 0.08355007 0.56718750
#>             pr_auc  maximize       3 0.7052403 0.7887512 0.14604998 0.54920647
#>              brier  minimize       3 0.2899371 0.2474772 0.09244876 0.22740236
#>           log_loss  minimize       3 0.9148567 0.6878170 0.40068648 0.67967828
#>      upper
#>  0.6625000
#>  0.6630208
#>  0.7406250
#>  0.9020833
#>  0.8291667
#>  0.7406250
#>  0.6384921
#>  0.3744940
#>  0.7255208
#>  0.7902897
#>  0.3885627
#>  1.3430188
```

Any reported predictive metrics are row-level outcomes under a declared
participant-grouped assessment design. They are not participant-level
psychological measurements and do not support causal or latent-state
claims.
