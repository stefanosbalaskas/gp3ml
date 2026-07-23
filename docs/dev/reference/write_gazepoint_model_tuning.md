# Write governed tuning and selection tables

Write governed tuning and selection tables

## Usage

``` r
write_gazepoint_model_tuning(
  x,
  directory,
  prefix = "gazepoint_model_tuning",
  selection = NULL,
  overwrite = FALSE
)
```

## Arguments

- x:

  A `gp3ml_model_tuning` object.

- directory:

  Output directory.

- prefix:

  Filename prefix.

- selection:

  Optional `gp3ml_model_selection` to record.

- overwrite:

  Whether existing files may be replaced.

## Value

Named output paths, invisibly.
