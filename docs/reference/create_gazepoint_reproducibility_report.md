# Create a reproducibility report

Create a reproducibility report

## Usage

``` r
create_gazepoint_reproducibility_report(
  objects = list(),
  data = NULL,
  seeds = list(),
  notes = character(),
  project_path = getwd()
)
```

## Arguments

- objects:

  Named objects to fingerprint.

- data:

  Optional data frame to fingerprint.

- seeds:

  Named list of deterministic seeds.

- notes:

  Optional reproducibility notes.

- project_path:

  Project directory recorded in the report.

## Value

A `gp3ml_reproducibility_report` object containing runtime information,
object and data fingerprints, seeds, Git metadata, notes, and prohibited
uses.

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
report
#> <gp3ml_reproducibility_report> 2026-07-21 16:40:22 UTC
```
