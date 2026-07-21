# Print a Gazepoint ML leakage audit

Print a Gazepoint ML leakage audit

## Usage

``` r
# S3 method for class 'gazepoint_ml_leakage_audit'
print(x, ...)
```

## Arguments

- x:

  An object returned by
  [`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/reference/audit_gazepoint_ml_leakage.md).

- ...:

  Additional arguments, currently unused.

## Value

`x`, invisibly.

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
audit <- audit_gazepoint_ml_leakage(
  analysis = analysis,
  assessment = assessment,
  outcome = "outcome",
  predictors = c("fixation_duration", "pupil_change"),
  participant_id = "participant_id",
  trial_id = "trial_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants"
)
print(audit)
#> <gazepoint_ml_leakage_audit>
#> Overall status: PASS
#> Generalization target: new_participants
#> Rows: 4 analysis; 4 assessment
#> Non-passing checks: 0
#> No leakage issues were detected by the implemented checks.
```
