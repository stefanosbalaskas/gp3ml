# Declare a frozen-analysis-plan contract

Declare a frozen-analysis-plan contract

## Usage

``` r
declare_gazepoint_analysis_plan(
  research_question,
  scientific_purpose,
  outcome,
  outcome_definition,
  predictors,
  generalization_target,
  grouping_variables = character(),
  eligible_population,
  exclusion_rules = character(),
  preprocessing_plan,
  candidate_models,
  primary_metric,
  secondary_metrics = character(),
  calibration_metric = NULL,
  uncertainty_method,
  threshold_policy = NULL,
  external_validation_required = FALSE,
  seed_strategy,
  prohibited_interpretations = gp3ml_prohibited_uses()
)
```

## Arguments

- research_question:

  Research question.

- scientific_purpose:

  Explicit scientific purpose.

- outcome:

  Outcome name.

- outcome_definition:

  Operational definition of the observed outcome.

- predictors:

  Predeclared predictors.

- generalization_target:

  Intended generalization target.

- grouping_variables:

  Grouping columns.

- eligible_population:

  Eligibility statement.

- exclusion_rules:

  Character vector of predeclared exclusions.

- preprocessing_plan:

  Preprocessing plan.

- candidate_models:

  Candidate model specifications or names.

- primary_metric:

  Primary metric.

- secondary_metrics:

  Secondary metrics.

- calibration_metric:

  Calibration metric.

- uncertainty_method:

  Uncertainty method.

- threshold_policy:

  Threshold/decision policy.

- external_validation_required:

  Whether independent validation is required.

- seed_strategy:

  Deterministic seed strategy.

- prohibited_interpretations:

  Character vector of prohibited interpretations.

## Value

A mutable `gp3ml_analysis_plan` until locked.
