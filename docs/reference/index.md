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
