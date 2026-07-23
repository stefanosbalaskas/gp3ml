# Write a reproducibility report

Write a reproducibility report

## Usage

``` r
write_gazepoint_reproducibility_report(report, path, overwrite = FALSE)
```

## Arguments

- report:

  A `gp3ml_reproducibility_report` object.

- path:

  Destination Markdown file path.

- overwrite:

  Whether an existing file may be replaced.

## Value

The destination path, returned invisibly after the reproducibility
report is written.

## Examples

``` r
example_data <- data.frame(
  trial_id = sprintf("T%02d", 1:6),
  fixation_duration = c(190, 205, 198, 214, 202, 220),
  stringsAsFactors = FALSE
)
report <- create_gazepoint_reproducibility_report(
  objects = list(
    fixation_values = example_data$fixation_duration
  ),
  data = example_data,
  seeds = list(example = 101L),
  notes = "Synthetic documentation example.",
  project_path = tempdir()
)
output <- tempfile(fileext = ".md")
write_gazepoint_reproducibility_report(report, output)
file.exists(output)
#> [1] TRUE
unlink(output)
```
