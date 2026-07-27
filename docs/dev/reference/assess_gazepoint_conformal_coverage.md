# Assess conformal coverage

Assess conformal coverage

## Usage

``` r
assess_gazepoint_conformal_coverage(
  object,
  truth,
  interval = NULL,
  set = NULL,
  unit = NULL
)
```

## Arguments

- object:

  A `gp3ml_conformal_fit`.

- truth:

  Observed outcomes.

- interval:

  Regression interval data frame.

- set:

  Classification set data frame.

- unit:

  Optional assessment-unit identifier.

## Value

A `gp3ml_conformal_coverage`.
