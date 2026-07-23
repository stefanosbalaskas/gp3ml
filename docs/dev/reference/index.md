# Package index

## Package

- [`gp3ml`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gp3ml-package.md)
  [`gp3ml-package`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gp3ml-package.md)
  : gp3ml: Governance-First Predictive Modelling for 'Gazepoint'
  Research

## Leakage auditing

Audit partition leakage and export structured results.

- [`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/audit_gazepoint_ml_leakage.md)
  : Audit leakage between predictive-analysis partitions
- [`print(`*`<gazepoint_ml_leakage_audit>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_ml_leakage_audit.md)
  : Print a Gazepoint ML leakage audit
- [`write_gazepoint_ml_leakage_audit_csv()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_ml_leakage_audit_csv.md)
  : Write a Gazepoint ML leakage-audit table to CSV

## Feature provenance

Record and validate intended predictor provenance.

- [`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_feature_manifest.md)
  : Create a Gazepoint feature-provenance manifest
- [`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_feature_manifest.md)
  : Validate a Gazepoint feature-provenance manifest
- [`print(`*`<gazepoint_feature_manifest_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_feature_manifest_validation.md)
  : Print feature-manifest validation
- [`write_gazepoint_feature_manifest_csv()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_feature_manifest_csv.md)
  : Write a Gazepoint feature manifest or validation table to CSV

## Group-aware splitting

Create and validate deterministic grouped holdout partitions.

- [`split_gazepoint_ml_data()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/split_gazepoint_ml_data.md)
  : Create a deterministic group-aware Gazepoint holdout split
- [`validate_gazepoint_ml_split()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_ml_split.md)
  : Validate a group-aware Gazepoint holdout split
- [`print(`*`<gazepoint_ml_split>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_ml_split.md)
  : Print a group-aware Gazepoint split
- [`print(`*`<gazepoint_ml_split_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_ml_split_validation.md)
  : Print group-aware split validation
- [`write_gazepoint_ml_split_csv()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_ml_split_csv.md)
  : Write group-aware split tables to CSV

## Group-aware resampling

Create, validate, audit, and export deterministic grouped folds.

- [`create_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_group_folds.md)
  : Create deterministic group-aware Gazepoint resampling folds
- [`validate_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_group_folds.md)
  : Validate group-aware Gazepoint resampling folds
- [`audit_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/audit_gazepoint_group_folds.md)
  : Aggregate leakage audits across group-aware folds
- [`print(`*`<gazepoint_group_folds>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_group_folds.md)
  : Print group-aware Gazepoint resampling folds
- [`print(`*`<gazepoint_group_folds_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_group_folds_validation.md)
  : Print group-aware fold validation
- [`print(`*`<gazepoint_group_folds_audit>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_group_folds_audit.md)
  : Print aggregated group-fold leakage auditing
- [`write_gazepoint_group_folds_csv()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_group_folds_csv.md)
  : Write group-aware resampling tables to CSV

## Resampling diagnostics

Diagnose fold balance, coverage, exclusions, and outcomes.

- [`diagnose_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/diagnose_gazepoint_group_folds.md)
  : Diagnose group-aware Gazepoint resampling folds
- [`validate_gazepoint_fold_diagnostics()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_fold_diagnostics.md)
  : Validate Gazepoint fold diagnostics
- [`print(`*`<gazepoint_fold_diagnostics>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_fold_diagnostics.md)
  : Print Gazepoint fold diagnostics
- [`print(`*`<gazepoint_fold_diagnostics_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/print.gazepoint_fold_diagnostics_validation.md)
  : Print Gazepoint fold-diagnostics validation
- [`write_gazepoint_fold_diagnostics_csv()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_fold_diagnostics_csv.md)
  : Write Gazepoint fold diagnostics to CSV files

## Repository-aware fold evaluation

Fit fold-local preprocessing and models across materialized grouped
folds.

- [`evaluate_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_group_folds.md)
  [`print(`*`<gp3ml_resample_evaluation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_group_folds.md)
  : Evaluate a governed model specification across materialized grouped
  folds
- [`collect_gazepoint_fold_predictions()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/collect_gazepoint_fold_predictions.md)
  : Collect predictions from a grouped-fold evaluation
- [`summarize_gazepoint_resample_performance()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/summarize_gazepoint_resample_performance.md)
  [`print(`*`<gp3ml_resample_performance_summary>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/summarize_gazepoint_resample_performance.md)
  : Summarize repeated grouped-resampling performance
- [`validate_gazepoint_resample_evaluation()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_resample_evaluation.md)
  [`print(`*`<gp3ml_resample_evaluation_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_resample_evaluation.md)
  : Validate a grouped-fold evaluation result
- [`write_gazepoint_resample_evaluation()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_resample_evaluation.md)
  : Write grouped-fold evaluation tables

## Governed comparison and tuning

Materialize, evaluate, compare, and review explicit model candidates.

- [`create_gazepoint_tuning_grid()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_tuning_grid.md)
  [`print(`*`<gp3ml_tuning_grid>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_tuning_grid.md)
  : Create an explicit governed tuning grid
- [`tune_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/tune_gazepoint_model.md)
  [`print(`*`<gp3ml_model_tuning>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/tune_gazepoint_model.md)
  : Evaluate every governed candidate on the same grouped folds
- [`compare_gazepoint_models()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/compare_gazepoint_models.md)
  : Compare governed model candidates without selecting a winner
- [`select_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/select_gazepoint_model.md)
  [`print(`*`<gp3ml_model_selection>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/select_gazepoint_model.md)
  : Select a governed candidate using an explicit metric and direction
- [`validate_gazepoint_model_tuning()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_model_tuning.md)
  [`print(`*`<gp3ml_model_tuning_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_model_tuning.md)
  : Validate governed tuning results
- [`write_gazepoint_model_tuning()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_model_tuning.md)
  : Write governed tuning and selection tables

## Nested grouped resampling

Isolate inner tuning inside every outer analysis partition.

- [`create_gazepoint_nested_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_nested_folds.md)
  [`print(`*`<gp3ml_nested_folds>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_nested_folds.md)
  : Create nested grouped resampling from mature outer folds
- [`audit_gazepoint_nested_resampling()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/audit_gazepoint_nested_resampling.md)
  [`print(`*`<gp3ml_nested_resampling_audit>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/audit_gazepoint_nested_resampling.md)
  : Audit nested grouped resampling for outer-assessment leakage
- [`validate_gazepoint_nested_folds()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_nested_folds.md)
  [`print(`*`<gp3ml_nested_folds_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_nested_folds.md)
  : Validate nested grouped folds
- [`evaluate_gazepoint_nested_resampling()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_nested_resampling.md)
  [`print(`*`<gp3ml_nested_evaluation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_nested_resampling.md)
  : Evaluate nested grouped resampling with inner governed tuning
- [`validate_gazepoint_nested_evaluation()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_nested_evaluation.md)
  [`print(`*`<gp3ml_nested_evaluation_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_nested_evaluation.md)
  : Validate a nested evaluation
- [`write_gazepoint_nested_evaluation()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_nested_evaluation.md)
  : Write nested-resampling evaluation tables

## Target-aligned uncertainty

Record observation, cluster, fold, and repeat uncertainty without
relabelling units.

- [`bootstrap_gazepoint_metrics_by_unit()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/bootstrap_gazepoint_metrics_by_unit.md)
  [`print(`*`<gp3ml_target_uncertainty>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/bootstrap_gazepoint_metrics_by_unit.md)
  : Generalization-target-aligned bootstrap uncertainty
- [`summarize_gazepoint_resample_uncertainty()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/summarize_gazepoint_resample_uncertainty.md)
  [`print(`*`<gp3ml_resample_uncertainty>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/summarize_gazepoint_resample_uncertainty.md)
  : Summarize uncertainty across folds or repeats
- [`validate_gazepoint_target_uncertainty()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_target_uncertainty.md)
  [`print(`*`<gp3ml_uncertainty_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_target_uncertainty.md)
  : Validate target-aligned uncertainty metadata
- [`write_gazepoint_target_uncertainty()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_target_uncertainty.md)
  : Write target-aligned uncertainty tables

## External validation and transportability

Declare independent data and report performance, drift, schema, and
coverage.

- [`declare_gazepoint_external_dataset()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/declare_gazepoint_external_dataset.md)
  [`print(`*`<gp3ml_external_dataset_declaration>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/declare_gazepoint_external_dataset.md)
  : Declare an external dataset and its independence status
- [`evaluate_gazepoint_external_transportability()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_external_transportability.md)
  [`print(`*`<gp3ml_transportability_report>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_gazepoint_external_transportability.md)
  : Evaluate external transportability and validation status
- [`validate_gazepoint_transportability()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_transportability.md)
  [`print(`*`<gp3ml_transportability_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_transportability.md)
  : Validate an external transportability report
- [`write_gazepoint_transportability_report()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_transportability_report.md)
  : Write an expanded transportability report

## Synthetic workflows and release reporting

Deterministic demonstrations and release-ready governance records.

- [`simulate_gazepoint_governed_data()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/simulate_gazepoint_governed_data.md)
  : Simulate governed synthetic Gazepoint-derived data
- [`create_gazepoint_synthetic_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_synthetic_manifest.md)
  : Create a synthetic governed feature manifest
- [`create_gazepoint_synthetic_task()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_synthetic_task.md)
  : Create one of the governed synthetic demonstration tasks
- [`create_gazepoint_release_model_card()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_release_model_card.md)
  [`print(`*`<gp3ml_release_model_card>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_release_model_card.md)
  : Create a release-ready governed model card
- [`write_gazepoint_release_model_card()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_release_model_card.md)
  : Write a release-ready governed model card
- [`create_gazepoint_release_evidence()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_release_evidence.md)
  [`print(`*`<gp3ml_release_evidence>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_release_evidence.md)
  : Create a release evidence manifest

## Governed modelling core

Task governance, preprocessing, model fitting, performance, calibration,
uncertainty, external validation, model cards, and reproducibility
reporting.

- [`declare_gazepoint_task()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/declare_gazepoint_task.md)
  : Declare a governed Gazepoint prediction task
- [`assert_gp3ml_use_case()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/assert_gp3ml_use_case.md)
  : Assert that a task is within the permitted gp3ml scope
- [`validate_gazepoint_ml_roles()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_ml_roles.md)
  : Validate outcome, predictor, identifier, and grouping roles
- [`gp3ml_prohibited_uses()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gp3ml_prohibited_uses.md)
  : Prohibited gp3ml uses
- [`fit_gazepoint_preprocessor()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_preprocessor.md)
  : Fit a fold-local preprocessing engine
- [`bake_gazepoint_preprocessor()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/bake_gazepoint_preprocessor.md)
  : Apply a fitted preprocessing engine
- [`gp3ml_available_engines()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gp3ml_available_engines.md)
  : List available model engines
- [`integrate_black_box_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/integrate_black_box_model.md)
  : Integrate a controlled black-box model engine
- [`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_model.md)
  : Fit a governed Gazepoint model
- [`train_gazepoint_classifier()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/train_gazepoint_classifier.md)
  : Generic governed binary-classifier training wrapper
- [`predict(`*`<gp3ml_model>`*`)`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/predict.gp3ml_model.md)
  : Predict from a gp3ml model
- [`fit_gazepoint_deep_model()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_deep_model.md)
  : Fit an optional governed deep-learning model through keras3
- [`gazepoint_classification_metrics()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gazepoint_classification_metrics.md)
  : Binary classification metrics
- [`gazepoint_regression_metrics()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gazepoint_regression_metrics.md)
  : Regression metrics
- [`gazepoint_performance_metrics()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/gazepoint_performance_metrics.md)
  : Task-aware performance metrics
- [`bootstrap_gazepoint_metrics()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/bootstrap_gazepoint_metrics.md)
  : Bootstrap uncertainty intervals for performance metrics
- [`fit_gazepoint_calibrator()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/fit_gazepoint_calibrator.md)
  : Fit a probability calibrator
- [`apply_gazepoint_calibrator()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/apply_gazepoint_calibrator.md)
  : Apply a fitted probability calibrator
- [`assess_gazepoint_calibration()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/assess_gazepoint_calibration.md)
  : Calibration assessment with bootstrap uncertainty
- [`evaluate_external_validation()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/evaluate_external_validation.md)
  : Evaluate an independent external-validation dataset
- [`create_external_validation_report()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_external_validation_report.md)
  : Create an external-validation report object
- [`write_external_validation_report()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_external_validation_report.md)
  : Write an external-validation report
- [`create_gazepoint_model_card()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_model_card.md)
  : Create a governance-focused model card
- [`write_gazepoint_model_card()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_model_card.md)
  : Write a model card
- [`create_gazepoint_reproducibility_report()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/create_gazepoint_reproducibility_report.md)
  : Create a reproducibility report
- [`write_gazepoint_reproducibility_report()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/write_gazepoint_reproducibility_report.md)
  : Write a reproducibility report
