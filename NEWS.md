# gp3ml 0.0.0.9000

## Resampling diagnostics milestone

- Added `diagnose_gazepoint_group_folds()` for structured diagnostics of grouped resampling plans.
- Added fold-level and repeat-level summaries of analysis, assessment, and excluded row counts.
- Added assessment fold-size imbalance ratios with configurable review and failure thresholds.
- Added group-balance summaries for participant, participant-trial, and stimulus units.
- Added assessment-coverage diagnostics verifying that each source row is assessed exactly once per repeat.
- Added categorical outcome-level representation and continuous numeric outcome summaries by fold and partition.
- Added explicit exclusion summaries for crossed participant-by-stimulus resampling designs.
- Added `validate_gazepoint_fold_diagnostics()` with structured `pass`, `review`, and `fail` findings.
- Added print methods and `write_gazepoint_fold_diagnostics_csv()` for eight machine-readable diagnostic tables.
- Added deterministic regression coverage across all four supported generalization targets.
- This milestone does not introduce preprocessing, feature selection, tuning, nested resampling, or model fitting.

## Group-aware resampling milestone

- Added `create_gazepoint_group_folds()` for deterministic
  repeated group-aware V-fold plans.
- Required an explicit predictive-generalization target and a
  passing feature-provenance manifest before fold construction.
- Added support for new trials among known participants, new
  participants, new stimuli, and simultaneous new-participant
  and new-stimulus generalization.
- Added crossed participant-stimulus assessment blocks with
  explicit accounting for excluded cross-block rows.
- Added `validate_gazepoint_group_folds()` for fold counts,
  source-row accounting, assessment coverage, partition
  consistency, provenance, and leakage-audit validation.
- Added `audit_gazepoint_group_folds()` for aggregating embedded
  fold-level leakage audits.
- Added print methods and `write_gazepoint_group_folds_csv()`
  for machine-readable summaries and optional fold export.
- Added deterministic synthetic tests for all supported targets,
  repeated folds, invalid requests, auditing, and CSV output.
- No preprocessing, automated feature selection, tuning, nested
  resampling, or model fitting was introduced.

## Group-aware holdout-splitting milestone

- Added `split_gazepoint_ml_data()` for deterministic
  group-aware analysis and assessment partitions.
- Required an explicit predictive-generalization target and a
  passing feature-provenance manifest before splitting.
- Added support for new trials among known participants, new
  participants, new stimuli, and simultaneous new-participant
  and new-stimulus generalization.
- Preserved participant-trial, participant, or stimulus groups
  according to the declared target.
- Added strict participant–stimulus block separation with
  explicit accounting for excluded cross-block rows.
- Added `validate_gazepoint_ml_split()` with source-row,
  partition-structure, provenance, and leakage-audit checks.
- Added print methods and
  `write_gazepoint_ml_split_csv()` for machine-readable export.
- Added deterministic synthetic tests covering all supported
  generalization targets and intentionally invalid requests.
- No preprocessing, automated feature selection, resampling, or
  model fitting was introduced.

## Feature-provenance milestone

- Added `create_gazepoint_feature_manifest()` for recording
  predictor origins, transformations, availability stages,
  roles, and preprocessing scopes.
- Added `validate_gazepoint_feature_manifest()` with structured
  `pass`, `review`, and `fail` results.
- Added checks for outcome-derived, post-outcome, identifier,
  and prediction-time-unavailable features.
- Added checks for incomplete provenance and preprocessing
  incompatible with declared fold-local requirements.
- Added `write_gazepoint_feature_manifest_csv()` for exporting
  manifests and validation tables.
- Added deterministic synthetic tests for safe, incomplete,
  and intentionally unsafe manifests.

## Leakage-audit milestone

- Added `audit_gazepoint_ml_leakage()` for structured auditing
  of already-defined analysis and assessment partitions.
- Added explicit checks for participant, participant-trial, and
  stimulus compatibility with declared generalization targets.
- Added checks for exact-row overlap, duplicated rows, repeated
  predictor profiles, identifier predictors, target-derived
  predictors, and post-outcome predictors.
- Added `pass`, `review`, and `fail` audit statuses with complete
  check, issue, and partition-summary tables.
- Added `write_gazepoint_ml_leakage_audit_csv()` for
  machine-readable audit export.
- Added deterministic synthetic tests covering clean and
  intentionally contaminated partitions.

## Initial development bootstrap

- Created the minimal R package structure.
- Added explicit model-governance and prohibited-use statements.
- Restricted the initial scope to validation and governance.
- Confirmed that examples and tests will use deterministic
  synthetic data only.
- No model-training functions have been implemented.
