# Audit leakage between predictive-analysis partitions

Audits already-defined analysis and assessment partitions for common
forms of leakage and for incompatibility with a declared generalization
target. The function does not create data splits, preprocess variables,
select features, or fit predictive models.

## Usage

``` r
audit_gazepoint_ml_leakage(
  analysis,
  assessment,
  outcome,
  predictors,
  participant_id = NULL,
  trial_id = NULL,
  stimulus_id = NULL,
  generalization_target = c("new_trials_known_participants", "new_participants",
    "new_stimuli", "new_participants_and_new_stimuli"),
  target_derived = character(),
  post_outcome = character()
)
```

## Arguments

- analysis:

  A data frame containing the analysis or training partition.

- assessment:

  A data frame containing the assessment or test partition.

- outcome:

  A single column name identifying the outcome.

- predictors:

  A character vector identifying intended predictor columns.

- participant_id:

  An optional participant-identifier column.

- trial_id:

  An optional trial-identifier column.

- stimulus_id:

  An optional stimulus-identifier column.

- generalization_target:

  The predictive generalization target. One of
  `"new_trials_known_participants"`, `"new_participants"`,
  `"new_stimuli"`, or `"new_participants_and_new_stimuli"`.

- target_derived:

  Character vector of columns known to have been derived directly from
  the outcome.

- post_outcome:

  Character vector of columns measured or constructed after the outcome
  became available.

## Value

An object of class `gazepoint_ml_leakage_audit`. The object contains an
overall status, partition summary, complete check table, and
machine-readable table of non-passing issues.

## Details

The overall status is `"fail"` when at least one failing check is
present, `"review"` when no failing checks are present but at least one
review item is present, and `"pass"` otherwise.

When `participant_id` is supplied, trial overlap is evaluated using
composite participant-trial units. This permits trial labels such as
`"T01"` to be reused by different participants without being treated as
leakage. Without `participant_id`, `trial_id` is assumed to be globally
unique.

The audit can identify structural leakage visible in the supplied
partitions and declared variable roles. It cannot prove that
preprocessing or feature selection was estimated inside resampling
folds. Those operations require separate provenance and resampling
safeguards.

The function does not determine whether an outcome is scientifically or
ethically appropriate. All uses remain subject to the package governance
and prohibited-use statements.

## Examples

``` r
analysis <- data.frame(
  participant_id = c("P01", "P01", "P02", "P02"),
  trial_id = c("T01", "T02", "T03", "T04"),
  stimulus_id = c("S01", "S02", "S03", "S04"),
  outcome = c(0, 1, 0, 1),
  fixation_duration = c(210, 240, 225, 260),
  pupil_change = c(0.10, 0.16, 0.12, 0.18)
)

assessment <- data.frame(
  participant_id = c("P03", "P03", "P04", "P04"),
  trial_id = c("T05", "T06", "T07", "T08"),
  stimulus_id = c("S05", "S06", "S07", "S08"),
  outcome = c(1, 0, 1, 0),
  fixation_duration = c(275, 230, 290, 245),
  pupil_change = c(0.21, 0.11, 0.24, 0.14)
)

audit_gazepoint_ml_leakage(
  analysis = analysis,
  assessment = assessment,
  outcome = "outcome",
  predictors = c("fixation_duration", "pupil_change"),
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants"
)
#> <gazepoint_ml_leakage_audit>
#> Overall status: PASS
#> Generalization target: new_participants
#> Rows: 4 analysis; 4 assessment
#> Non-passing checks: 0
#> No leakage issues were detected by the implemented checks.
```
