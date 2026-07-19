# Write group-aware split tables to CSV

Write group-aware split tables to CSV

## Usage

``` r
write_gazepoint_ml_split_csv(
  x,
  directory,
  prefix = "gazepoint_ml_split",
  tables = c("analysis", "assessment", "excluded", "assignment", "summary",
    "group_counts", "checks", "issues"),
  overwrite = FALSE,
  na = ""
)
```

## Arguments

- x:

  A `gazepoint_ml_split` object.

- directory:

  Output directory.

- prefix:

  Filename prefix.

- tables:

  Tables to export.

- overwrite:

  Whether existing files may be replaced.

- na:

  Character representation of missing values.

## Value

A named character vector of normalized file paths, invisibly.
