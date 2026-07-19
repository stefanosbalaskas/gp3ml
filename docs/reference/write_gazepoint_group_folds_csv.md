# Write group-aware resampling tables to CSV

Write group-aware resampling tables to CSV

## Usage

``` r
write_gazepoint_group_folds_csv(
  x,
  directory,
  prefix = "gazepoint_group_folds",
  tables = c("assignments", "fold_summary", "group_counts", "group_mapping",
    "validation_checks", "validation_issues", "audit_summary", "audit_checks",
    "audit_issues"),
  include_fold_data = FALSE,
  overwrite = FALSE,
  na = ""
)
```

## Arguments

- x:

  A `gazepoint_group_folds` object.

- directory:

  Output directory.

- prefix:

  Non-empty filename prefix.

- tables:

  Character vector selecting summary tables.

- include_fold_data:

  Logical. Whether every materialized fold partition should also be
  written.

- overwrite:

  Logical. Whether existing files may be replaced.

- na:

  Character representation of missing values.

## Value

A named character vector of normalized output paths, invisibly.
