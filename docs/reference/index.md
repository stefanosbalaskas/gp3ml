# Package index

## Package

- [`gp3ml`](https://stefanosbalaskas.github.io/gp3ml/reference/gp3ml-package.md)
  [`gp3ml-package`](https://stefanosbalaskas.github.io/gp3ml/reference/gp3ml-package.md)
  : gp3ml: Leakage-Safe Predictive Validation for Gazepoint Research

## Leakage auditing

Audit partition leakage and export structured results.

- [`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_ml_leakage.md)
  : Audit leakage between predictive-analysis partitions
- [`print(`*`<gazepoint_ml_leakage_audit>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_ml_leakage_audit.md)
  : Print a Gazepoint ML leakage audit
- [`write_gazepoint_ml_leakage_audit_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_ml_leakage_audit_csv.md)
  : Write a Gazepoint ML leakage-audit table to CSV

## Feature provenance

Record and validate intended predictor provenance.

- [`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_feature_manifest.md)
  : Create a Gazepoint feature-provenance manifest
- [`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_feature_manifest.md)
  : Validate a Gazepoint feature-provenance manifest
- [`print(`*`<gazepoint_feature_manifest_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_feature_manifest_validation.md)
  : Print feature-manifest validation
- [`write_gazepoint_feature_manifest_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_feature_manifest_csv.md)
  : Write a Gazepoint feature manifest or validation table to CSV

## Group-aware splitting

Create and validate deterministic grouped holdout partitions.

- [`split_gazepoint_ml_data()`](https://stefanosbalaskas.github.io/gp3ml/reference/split_gazepoint_ml_data.md)
  : Create a deterministic group-aware Gazepoint holdout split
- [`validate_gazepoint_ml_split()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_ml_split.md)
  : Validate a group-aware Gazepoint holdout split
- [`print(`*`<gazepoint_ml_split>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_ml_split.md)
  : Print a group-aware Gazepoint split
- [`print(`*`<gazepoint_ml_split_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_ml_split_validation.md)
  : Print group-aware split validation
- [`write_gazepoint_ml_split_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_ml_split_csv.md)
  : Write group-aware split tables to CSV

## Group-aware resampling

Create, validate, audit, and export deterministic grouped folds.

- [`create_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_group_folds.md)
  : Create deterministic group-aware Gazepoint resampling folds
- [`validate_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_group_folds.md)
  : Validate group-aware Gazepoint resampling folds
- [`audit_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_group_folds.md)
  : Aggregate leakage audits across group-aware folds
- [`print(`*`<gazepoint_group_folds>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_group_folds.md)
  : Print group-aware Gazepoint resampling folds
- [`print(`*`<gazepoint_group_folds_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_group_folds_validation.md)
  : Print group-aware fold validation
- [`print(`*`<gazepoint_group_folds_audit>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_group_folds_audit.md)
  : Print aggregated group-fold leakage auditing
- [`write_gazepoint_group_folds_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_group_folds_csv.md)
  : Write group-aware resampling tables to CSV

## Resampling diagnostics

Diagnose fold balance, coverage, exclusions, and outcome representation.

- [`diagnose_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/diagnose_gazepoint_group_folds.md)
  : Diagnose group-aware Gazepoint resampling folds
- [`validate_gazepoint_fold_diagnostics()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_fold_diagnostics.md)
  : Validate Gazepoint fold diagnostics
- [`print(`*`<gazepoint_fold_diagnostics>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_fold_diagnostics.md)
  : Print Gazepoint fold diagnostics
- [`print(`*`<gazepoint_fold_diagnostics_validation>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/print.gazepoint_fold_diagnostics_validation.md)
  : Print Gazepoint fold-diagnostics validation
- [`write_gazepoint_fold_diagnostics_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_fold_diagnostics_csv.md)
  : Write Gazepoint fold diagnostics to CSV files

## Governed modelling core

Governance-first task declaration, preprocessing, model fitting,
performance assessment, calibration, uncertainty, external validation,
model cards, and reproducibility reporting.

- [`declare_gazepoint_task()`](https://stefanosbalaskas.github.io/gp3ml/reference/declare_gazepoint_task.md)
  : Declare a governed Gazepoint prediction task
- [`assert_gp3ml_use_case()`](https://stefanosbalaskas.github.io/gp3ml/reference/assert_gp3ml_use_case.md)
  : Assert that a task is within the permitted gp3ml scope
- [`validate_gazepoint_ml_roles()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_ml_roles.md)
  : Validate outcome, predictor, identifier, and grouping roles
- [`gp3ml_prohibited_uses()`](https://stefanosbalaskas.github.io/gp3ml/reference/gp3ml_prohibited_uses.md)
  : Prohibited gp3ml uses
- [`fit_gazepoint_preprocessor()`](https://stefanosbalaskas.github.io/gp3ml/reference/fit_gazepoint_preprocessor.md)
  : Fit a fold-local preprocessing engine
- [`bake_gazepoint_preprocessor()`](https://stefanosbalaskas.github.io/gp3ml/reference/bake_gazepoint_preprocessor.md)
  : Apply a fitted preprocessing engine
- [`gp3ml_available_engines()`](https://stefanosbalaskas.github.io/gp3ml/reference/gp3ml_available_engines.md)
  : List available model engines
- [`integrate_black_box_model()`](https://stefanosbalaskas.github.io/gp3ml/reference/integrate_black_box_model.md)
  : Integrate a controlled black-box model engine
- [`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/reference/fit_gazepoint_model.md)
  : Fit a governed Gazepoint model
- [`train_gazepoint_classifier()`](https://stefanosbalaskas.github.io/gp3ml/reference/train_gazepoint_classifier.md)
  : Generic governed binary-classifier training wrapper
- [`predict(`*`<gp3ml_model>`*`)`](https://stefanosbalaskas.github.io/gp3ml/reference/predict.gp3ml_model.md)
  : Predict from a gp3ml model
- [`fit_gazepoint_deep_model()`](https://stefanosbalaskas.github.io/gp3ml/reference/fit_gazepoint_deep_model.md)
  : Fit an optional governed deep-learning model through keras3
- [`gazepoint_classification_metrics()`](https://stefanosbalaskas.github.io/gp3ml/reference/gazepoint_classification_metrics.md)
  : Binary classification metrics
- [`gazepoint_regression_metrics()`](https://stefanosbalaskas.github.io/gp3ml/reference/gazepoint_regression_metrics.md)
  : Regression metrics
- [`gazepoint_performance_metrics()`](https://stefanosbalaskas.github.io/gp3ml/reference/gazepoint_performance_metrics.md)
  : Task-aware performance metrics
- [`bootstrap_gazepoint_metrics()`](https://stefanosbalaskas.github.io/gp3ml/reference/bootstrap_gazepoint_metrics.md)
  : Bootstrap uncertainty intervals for performance metrics
- [`fit_gazepoint_calibrator()`](https://stefanosbalaskas.github.io/gp3ml/reference/fit_gazepoint_calibrator.md)
  : Fit a probability calibrator
- [`apply_gazepoint_calibrator()`](https://stefanosbalaskas.github.io/gp3ml/reference/apply_gazepoint_calibrator.md)
  : Apply a fitted probability calibrator
- [`assess_gazepoint_calibration()`](https://stefanosbalaskas.github.io/gp3ml/reference/assess_gazepoint_calibration.md)
  : Calibration assessment with bootstrap uncertainty
- [`evaluate_external_validation()`](https://stefanosbalaskas.github.io/gp3ml/reference/evaluate_external_validation.md)
  : Evaluate an independent external-validation dataset
- [`create_external_validation_report()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_external_validation_report.md)
  : Create an external-validation report object
- [`write_external_validation_report()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_external_validation_report.md)
  : Write an external-validation report
- [`create_gazepoint_model_card()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_model_card.md)
  : Create a governance-focused model card
- [`write_gazepoint_model_card()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_model_card.md)
  : Write a model card
- [`create_gazepoint_reproducibility_report()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_reproducibility_report.md)
  : Create a reproducibility report
- [`write_gazepoint_reproducibility_report()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_reproducibility_report.md)
  : Write a reproducibility report
