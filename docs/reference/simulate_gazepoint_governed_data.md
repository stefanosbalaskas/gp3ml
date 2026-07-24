# Simulate governed synthetic Gazepoint-derived data

Creates deterministic, non-sensitive synthetic data for package
examples, tests, and website articles. The generated outcomes are
explicitly observed: a predefined recording-quality review status, an
experimentally assigned condition, and a non-sensitive recorded
response.

## Usage

``` r
simulate_gazepoint_governed_data(
  n_participants = 30L,
  n_stimuli = 8L,
  trials_per_cell = 2L,
  seed = 1L
)
```

## Arguments

- n_participants:

  Number of synthetic participants.

- n_stimuli:

  Number of synthetic stimuli.

- trials_per_cell:

  Number of trials per participant-stimulus cell.

- seed:

  Deterministic random seed.

## Value

A data frame containing identifiers, observed outcomes, and predeclared
synthetic predictors.

## Examples

``` r
synthetic <- simulate_gazepoint_governed_data(
  n_participants = 12L,
  n_stimuli = 4L,
  trials_per_cell = 1L,
  seed = 101L
)
table(synthetic$quality_status)
#>
#>   pass review
#>     41      7
```
