# Create a lightweight cross-package Gazepoint handoff

Create a lightweight cross-package Gazepoint handoff

## Usage

``` r
create_gazepoint_handoff(
  data,
  source_package,
  source_version = NULL,
  producer = NULL,
  keys,
  outcome = NULL,
  predictors = character(),
  feature_manifest = NULL,
  notes = character()
)
```

## Arguments

- data:

  Prepared data frame.

- source_package:

  Upstream source package or `study_design`/`custom`.

- source_version:

  Optional source-package version.

- producer:

  Optional upstream function/workflow label.

- keys:

  Character vector of row-identifying join keys.

- outcome:

  Optional observed outcome column.

- predictors:

  Optional prepared predictor columns.

- feature_manifest:

  Optional gp3ml feature-provenance manifest.

- notes:

  Optional handoff notes.

## Value

A `gp3ml_handoff` object.
