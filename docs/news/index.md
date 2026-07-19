# Changelog

## gp3ml 0.0.0.9000

### Feature-provenance milestone

- Added
  [`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_feature_manifest.md)
  for recording predictor origins, transformations, availability stages,
  roles, and preprocessing scopes.
- Added
  [`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_feature_manifest.md)
  with structured `pass`, `review`, and `fail` results.
- Added checks for outcome-derived, post-outcome, identifier, and
  prediction-time-unavailable features.
- Added checks for incomplete provenance and preprocessing incompatible
  with declared fold-local requirements.
- Added
  [`write_gazepoint_feature_manifest_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_feature_manifest_csv.md)
  for exporting manifests and validation tables.
- Added deterministic synthetic tests for safe, incomplete, and
  intentionally unsafe manifests.

### Leakage-audit milestone

- Added
  [`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_ml_leakage.md)
  for structured auditing of already-defined analysis and assessment
  partitions.
- Added explicit checks for participant, participant-trial, and stimulus
  compatibility with declared generalization targets.
- Added checks for exact-row overlap, duplicated rows, repeated
  predictor profiles, identifier predictors, target-derived predictors,
  and post-outcome predictors.
- Added `pass`, `review`, and `fail` audit statuses with complete check,
  issue, and partition-summary tables.
- Added
  [`write_gazepoint_ml_leakage_audit_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_ml_leakage_audit_csv.md)
  for machine-readable audit export.
- Added deterministic synthetic tests covering clean and intentionally
  contaminated partitions.

### Initial development bootstrap

- Created the minimal R package structure.
- Added explicit model-governance and prohibited-use statements.
- Restricted the initial scope to validation and governance.
- Confirmed that examples and tests will use deterministic synthetic
  data only.
- No model-training functions have been implemented.
