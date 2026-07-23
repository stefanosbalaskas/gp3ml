# Write a Gazepoint ML leakage-audit table to CSV

Writes one machine-readable table from a leakage-audit object to a UTF-8
CSV file. Existing files are not replaced unless explicitly permitted.

## Usage

``` r
write_gazepoint_ml_leakage_audit_csv(
  x,
  file,
  table = c("issues", "checks", "partition_summary"),
  overwrite = FALSE,
  na = ""
)
```

## Arguments

- x:

  An object returned by
  [`audit_gazepoint_ml_leakage()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/audit_gazepoint_ml_leakage.md).

- file:

  A single output file path ending in `.csv`.

- table:

  The audit table to export. One of `"issues"`, `"checks"`, or
  `"partition_summary"`.

- overwrite:

  Logical. When `FALSE`, the default, an existing output file causes an
  error.

- na:

  Character value used for missing values in the CSV file.

## Value

The normalized output path, invisibly.

## Examples

``` r
analysis <- data.frame(
  participant_id = c("P01", "P02"),
  trial_id = c("T01", "T02"),
  outcome = c(0, 1),
  feature = c(1.2, 1.8)
)

assessment <- data.frame(
  participant_id = c("P03", "P04"),
  trial_id = c("T03", "T04"),
  outcome = c(1, 0),
  feature = c(2.1, 2.4)
)

audit <- audit_gazepoint_ml_leakage(
  analysis = analysis,
  assessment = assessment,
  outcome = "outcome",
  predictors = "feature",
  participant_id = "participant_id",
  trial_id = "trial_id",
  generalization_target = "new_participants"
)

output <- tempfile(fileext = ".csv")

write_gazepoint_ml_leakage_audit_csv(
  audit,
  output,
  table = "checks"
)

unlink(output)
```
