
<!-- README.md is generated from README.Rmd. Please edit README.Rmd. -->

# gp3ml

`gp3ml` is an R package under cautious development for leakage-resistant
and group-aware predictive validation using Gazepoint-derived research
data.

## Scope

The first development stages focus on:

- participant-, trial-, and stimulus-leakage auditing;
- explicit generalization-target declarations;
- outcome, predictor, and identifier-role validation;
- feature-provenance manifests;
- grouped train/test splitting;
- grouped and nested resampling plans;
- fold-overlap and balance diagnostics;
- calibration and uncertainty assessment;
- model-card and reproducibility reporting.

The package is not intended to be a generic wrapper around existing
machine-learning frameworks.

## Scientific safeguards

Participant overlap is treated as a failure when the declared target
requires generalization to new participants. Stimulus overlap is treated
as a failure when the declared target requires generalization to unseen
stimuli. Preprocessing and feature selection must be estimated inside
the relevant resampling folds.

All package examples and tests will use deterministic synthetic data.

## Leakage-audit workflow

`audit_gazepoint_ml_leakage()` audits already-defined analysis and
assessment partitions before predictive evaluation. It checks:

- compatibility with the declared generalization target;
- participant, participant-trial, and stimulus overlap;
- outcome and declared identifiers included as predictors;
- declared target-derived and post-outcome predictors;
- exact row overlap and repeated predictor profiles;
- duplicated rows and missing grouping identifiers; and
- identifier-like predictor names requiring manual review.

The returned audit has an overall `pass`, `review`, or `fail` status, a
complete check table, a non-passing issue table, and partition
summaries. Audit tables can be exported using
`write_gazepoint_ml_leakage_audit_csv()`.

``` r
analysis <- data.frame(
  participant_id = c("P01", "P02"),
  trial_id = c("T01", "T02"),
  stimulus_id = c("S01", "S02"),
  outcome = c(0, 1),
  fixation_duration = c(210, 245)
)

assessment <- data.frame(
  participant_id = c("P03", "P04"),
  trial_id = c("T03", "T04"),
  stimulus_id = c("S03", "S04"),
  outcome = c(1, 0),
  fixation_duration = c(275, 230)
)

audit <- audit_gazepoint_ml_leakage(
  analysis = analysis,
  assessment = assessment,
  outcome = "outcome",
  predictors = "fixation_duration",
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants"
)

audit
```

The audit identifies structural risks visible in the supplied partitions
and declared variable roles. It does not establish that preprocessing or
feature selection was estimated within resampling folds; those
safeguards require separate provenance and resampling infrastructure.

## Prohibited uses

The package does not support person identification, health inference,
protected-attribute prediction, or direct inference of emotion, stress,
mental state, cognition, comprehension, personality, deception, or
intent.

See:

- [`GOVERNANCE.md`](inst/governance/GOVERNANCE.md)
- [`PROHIBITED-USE.md`](inst/governance/PROHIBITED-USE.md)

## Development status

Version `0.0.0.9000` now includes the first governance feature:
structured leakage auditing for already-defined analysis and assessment
partitions, together with machine-readable CSV export.

No model-training interface, automated feature selection, or resampling
engine has been implemented.
