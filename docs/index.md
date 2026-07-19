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

[`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_ml_leakage.md)
audits already-defined analysis and assessment partitions before
predictive evaluation. It checks:

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
[`write_gazepoint_ml_leakage_audit_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_ml_leakage_audit_csv.md).

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

## Feature-provenance workflow

[`create_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_feature_manifest.md)
records the declared origin, transformation, availability, role, and
preprocessing scope of each intended predictor.

[`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_feature_manifest.md)
checks whether the manifest contains sufficient provenance metadata and
identifies predictors declared as outcome-derived, post-outcome,
unavailable at prediction time, identifiers, or incompatible with
required fold-local preprocessing.

``` r

manifest <- create_gazepoint_feature_manifest(
  features = c("fixation_duration", "pupil_change"),
  scientific_source = c(
    "Gazepoint fixation export",
    "Gazepoint all-gaze export"
  ),
  source_table = c("fixations", "all_gaze"),
  transformation = c(
    "Trial-level mean",
    "Baseline-adjusted change"
  ),
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = c("none", "resampling_fold"),
  fold_local_required = c(FALSE, TRUE)
)

validation <- validate_gazepoint_feature_manifest(manifest)
validation
```

Validation returns an overall `pass`, `review`, or `fail` status,
together with complete check and issue tables. The manifest or its
validation tables can be exported using
[`write_gazepoint_feature_manifest_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_feature_manifest_csv.md).

The manifest records declared provenance. It does not independently
verify that preprocessing was executed within the stated partition or
resampling scope.

## Group-aware holdout splitting

[`split_gazepoint_ml_data()`](https://stefanosbalaskas.github.io/gp3ml/reference/split_gazepoint_ml_data.md)
creates deterministic analysis and assessment partitions that preserve
the grouping unit implied by an explicit predictive-generalization
target. A passing feature-provenance manifest is required before
splitting, and the resulting partitions are checked using the leakage
audit.

``` r

split_data <- expand.grid(
  participant_id = sprintf("P%02d", 1:8),
  trial_id = sprintf("T%02d", 1:4),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

split_data$outcome <- as.integer(
  seq_len(nrow(split_data)) %% 2L
)

split_data$fixation_duration <-
  200 + seq_len(nrow(split_data))

split_data$pupil_change <-
  seq_len(nrow(split_data)) / 100

split <- split_gazepoint_ml_data(
  data = split_data,
  outcome = "outcome",
  predictors = c(
    "fixation_duration",
    "pupil_change"
  ),
  feature_manifest = manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  assessment_prop = 0.25,
  seed = 17
)

split
split$validation
```

Supported generalization targets are:

- `new_trials_known_participants`;
- `new_participants`;
- `new_stimuli`; and
- `new_participants_and_new_stimuli`.

For simultaneous participant and stimulus generalization, rows belonging
to only one held-out dimension are placed in the `excluded` partition.
This preserves strict separation between the analysis and assessment
participant–stimulus blocks while retaining complete source-row
accounting.

[`validate_gazepoint_ml_split()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_ml_split.md)
checks partition structure, source-row accounting, provenance status,
and the embedded leakage audit. Split assignments, summaries, validation
checks, and materialized partitions can be exported using
[`write_gazepoint_ml_split_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_ml_split_csv.md).

The splitter creates one deterministic holdout split. It does not
perform preprocessing, automated feature selection, cross-validation,
nested resampling, or model fitting.

## Group-aware resampling

[`create_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/create_gazepoint_group_folds.md)
creates deterministic repeated grouped V-fold plans for the same
explicit generalization targets supported by the holdout splitter. A
passing feature-provenance manifest is required, and every
analysis-assessment pair is checked using the leakage audit.

``` r

folds <- create_gazepoint_group_folds(
  data = split_data,
  outcome = "outcome",
  predictors = c(
    "fixation_duration",
    "pupil_change"
  ),
  feature_manifest = manifest,
  generalization_target = "new_participants",
  participant_id = "participant_id",
  trial_id = "trial_id",
  v = 4,
  repeats = 2,
  seed = 17
)

folds
folds$validation
folds$audit
```

Supported targets are new trials among known participants, new
participants, new stimuli, and simultaneous new-participant and
new-stimulus generalization. For simultaneous participant and stimulus
generalization, `v` may contain separate participant and stimulus fold
counts. Crossed assessment blocks preserve strict separation in both
dimensions, while cross-block rows are explicitly assigned to the
excluded partition.

[`validate_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/validate_gazepoint_group_folds.md)
checks fold counts, source-row accounting, assessment coverage,
materialized partitions, feature provenance, and embedded leakage
audits.
[`audit_gazepoint_group_folds()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_group_folds.md)
aggregates the fold-level audits. Assignments, summaries, validation
tables, audit tables, and optionally materialized partitions can be
exported using
[`write_gazepoint_group_folds_csv()`](https://stefanosbalaskas.github.io/gp3ml/reference/write_gazepoint_group_folds_csv.md).

The fold planner does not perform preprocessing, automated feature
selection, tuning, nested resampling, or model fitting.

## Prohibited uses

The package does not support person identification, health inference,
protected-attribute prediction, or direct inference of emotion, stress,
mental state, cognition, comprehension, personality, deception, or
intent.

See:

- [`GOVERNANCE.md`](https://stefanosbalaskas.github.io/gp3ml/inst/governance/GOVERNANCE.md)
- [`PROHIBITED-USE.md`](https://stefanosbalaskas.github.io/gp3ml/inst/governance/PROHIBITED-USE.md)

## Development status

Version `0.0.0.9000` includes structured leakage auditing,
feature-provenance manifests, deterministic group-aware holdout
splitting, repeated grouped resampling plans, fold validation,
aggregated leakage auditing, and machine-readable CSV export.

No model-training interface, automated feature selection, tuning, nested
resampling, or preprocessing engine has been implemented.
