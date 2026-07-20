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
