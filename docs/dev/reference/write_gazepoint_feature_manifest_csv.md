# Write a Gazepoint feature manifest or validation table to CSV

Writes a feature manifest or one table from a validated manifest to a
UTF-8 CSV file. Existing files are not replaced unless explicitly
permitted.

## Usage

``` r
write_gazepoint_feature_manifest_csv(
  x,
  file,
  table = c("manifest", "issues", "checks"),
  overwrite = FALSE,
  na = ""
)
```

## Arguments

- x:

  A `gazepoint_feature_manifest`, compatible data frame, or object
  returned by
  [`validate_gazepoint_feature_manifest()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/validate_gazepoint_feature_manifest.md).

- file:

  A single output path ending in `.csv`.

- table:

  Table to export. One of `"manifest"`, `"issues"`, or `"checks"`. Plain
  manifest inputs support only `"manifest"`.

- overwrite:

  Logical. When `FALSE`, the default, an existing file causes an error.

- na:

  Character value used for missing values.

## Value

The normalized output path, invisibly.

## Examples

``` r
manifest <- create_gazepoint_feature_manifest(
  features = "fixation_duration",
  scientific_source = "Gazepoint fixation export",
  source_table = "fixations",
  transformation = "Trial-level mean",
  availability_stage = "during_exposure",
  prediction_time_available = TRUE,
  preprocessing_scope = "none",
  fold_local_required = FALSE
)

output <- tempfile(fileext = ".csv")

write_gazepoint_feature_manifest_csv(
  manifest,
  output
)

unlink(output)
```
