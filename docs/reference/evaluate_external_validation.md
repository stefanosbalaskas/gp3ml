# Evaluate an independent external-validation dataset

Evaluate an independent external-validation dataset

## Usage

``` r
evaluate_external_validation(
  model,
  external_data,
  label = "external",
  threshold = model$threshold,
  bootstrap = 200L,
  seed = 1L
)
```

## Arguments

- model:

  A fitted `gp3ml_model` object.

- external_data:

  Independent external-validation data.

- label:

  Label identifying the validation dataset.

- threshold:

  Classification probability threshold.

- bootstrap:

  Number of calibration bootstrap replicates.

- seed:

  Deterministic random seed.
