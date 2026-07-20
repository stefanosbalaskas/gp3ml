# Write Gazepoint fold diagnostics to CSV files

Write Gazepoint fold diagnostics to CSV files

## Usage

``` r
write_gazepoint_fold_diagnostics_csv(
  x,
  directory,
  prefix = "gazepoint_fold_diagnostics",
  tables = c("fold_metrics", "repeat_metrics", "outcome_balance", "group_balance",
    "assessment_coverage", "exclusion_summary", "validation_checks", "validation_issues"),
  overwrite = FALSE,
  na = ""
)
```

## Arguments

- x:

  A `gazepoint_fold_diagnostics` object.

- directory:

  Output directory.

- prefix:

  File-name prefix.

- tables:

  Diagnostic tables to export.

- overwrite:

  Whether existing files may be overwritten.

- na:

  String used for missing values.

## Value

A named character vector of written file paths, invisibly.
