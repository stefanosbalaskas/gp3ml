# Changelog

## gp3ml 0.2.0

### Grouped evaluation and governed tuning

- Added fold-local evaluation across materialized
  `gazepoint_group_folds`, with retained predictions, metrics,
  exclusions, leakage audits, warnings, and failures.
- Added explicit deterministic tuning grids, candidate comparison, and
  human-reviewed selection requiring a predeclared metric and direction.
- Added nested grouped resampling with inner tuning isolated inside
  every outer analysis partition.

### Target-aligned uncertainty

- Added observation, participant-cluster, stimulus-cluster, and
  participant-and-stimulus bootstrap uncertainty with the resampling
  unit recorded explicitly.
- Added fold- and repeat-distribution summaries without relabelling
  row-level results as cluster-level estimates.

### External validation and reporting

- Added independent-dataset declarations, schema checks, predictor
  availability, prevalence shift, calibration drift,
  participant/stimulus coverage, and transportability limitations.
- Added explicit `not_externally_validated` status when no independent
  dataset is available.
- Added release-ready model cards recording selection procedures,
  uncertainty units, transportability status, limitations, and human
  oversight.

### Vignettes and validation

- Added nine deterministic synthetic vignettes covering recording
  quality, assigned conditions, observed outcomes, participant and
  stimulus generalization, simultaneous participant/stimulus
  generalization, contaminated manifests, nested resampling, and
  external validation.
- Added focused tests, an end-to-end smoke test, a full validation
  driver, and a read-only 0.2.0 release audit.

## gp3ml 0.1.0

### First formal release

- Established `gp3ml` as a governance-first package for
  leakage-resistant predictive modelling and validation using
  Gazepoint-derived research data.
- Restricted supported tasks to explicitly observed, non-sensitive
  outcomes and clearly declared scientific purposes.
- Added explicit prohibited-use documentation covering identification,
  authentication, diagnostic, protected-attribute, emotion, stress,
  personality, deception, cognition, comprehension, intent, and other
  mental-state inference.

### Governance, provenance, and leakage protection

- Added task declaration, use-case assertion, variable-role validation,
  and machine-readable prohibited-use helpers.
- Added feature-provenance manifests covering predictor origins,
  transformations, availability stages, roles, and preprocessing scope.
- Added structured leakage audits for row, participant,
  participant-trial, stimulus, identifier, target-derived, and
  post-outcome risks.

### Group-aware validation

- Added deterministic group-aware holdout splitting and repeated grouped
  resampling for new trials among known participants, new participants,
  new stimuli, and simultaneous new-participant and new-stimulus
  generalization.
- Materialized analysis, assessment, and explicitly excluded partitions
  with complete source-row accounting and embedded leakage audits.
- Added fold-balance, coverage, exclusion, and outcome-representation
  diagnostics with structured pass, review, and fail findings.

### Governed modelling core

- Added fold-local preprocessing objects with separate fitting and
  baking interfaces.
- Added governed model engines, explicit black-box integration,
  classification and regression metrics, calibration assessment, and
  explicitly labelled bootstrap metric uncertainty.
- Added external-validation evaluation and reporting without treating an
  internal holdout as external validation.
- Added model cards and reproducibility reports that record task
  purpose, governance decisions, model settings, performance,
  calibration, uncertainty, limitations, and reproducibility
  information.
- Model selection remains explicit and reviewable; the package does not
  perform autonomous black-box winner selection.

### Documentation and quality assurance

- Added machine-readable CSV, Markdown, and JSON reporting interfaces
  where supported by the relevant object.
- Added deterministic synthetic tests across supported generalization
  targets, governance failures, leakage cases, model engines, metrics,
  calibration, reporting, and serialization.
- Added complete pkgdown reference organization for the first formal
  release.
