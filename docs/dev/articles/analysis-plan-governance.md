# Frozen Analysis-Plan Governance

The analysis-plan contract records the scientific design before model
selection. Locking requires the optional `openssl` package and creates a
SHA-256 identifier.

``` r

plan <- declare_gazepoint_analysis_plan(
  research_question =
    "Can predefined recording-quality review status generalize to new participants?",
  scientific_purpose =
    "Evaluate a predefined, observed recording-quality endpoint.",
  outcome = "quality_status",
  outcome_definition = "Predefined observed QC review label.",
  predictors = c("fixation_duration", "pupil_change"),
  generalization_target = "new_participants",
  grouping_variables = "participant_id",
  eligible_population = "Participants meeting the study protocol.",
  preprocessing_plan = "Fit preprocessing only inside each analysis partition.",
  candidate_models = c("glm", "ranger"),
  primary_metric = "balanced_accuracy",
  secondary_metrics = c("sensitivity", "specificity"),
  calibration_metric = "brier",
  uncertainty_method = "participant_cluster_bootstrap",
  threshold_policy = "Select only within inner resampling.",
  external_validation_required = TRUE,
  seed_strategy = "Predeclared deterministic seeds."
)

locked <- lock_gazepoint_analysis_plan(plan)
locked$plan_id
#> [1] "gp3ml-plan-df6ea6e48d02"
```

Any later change to the outcome, predictor set, generalization target,
metric, preprocessing, or threshold policy should be represented as a
deviation rather than silently rewriting the original plan.
