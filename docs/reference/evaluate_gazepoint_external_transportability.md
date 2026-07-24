# Evaluate external transportability and validation status

An internal holdout or a dataset explicitly declared non-independent is
labelled `not_externally_validated`; it cannot generate an external-
validation claim.

## Usage

``` r
evaluate_gazepoint_external_transportability(
  model,
  development_data,
  external_data = NULL,
  declaration = NULL,
  development_evaluation = NULL,
  threshold = model$threshold,
  bootstrap = 200L,
  seed = 1L
)

# S3 method for class 'gp3ml_transportability_report'
print(x, ...)
```

## Arguments

- model:

  Fitted governed model.

- development_data:

  Data used to characterize development schema and group coverage.

- external_data:

  Candidate external data. May be `NULL` to create an explicit
  not-validated status.

- declaration:

  External dataset declaration. Required when external data are
  supplied.

- development_evaluation:

  Optional grouped development evaluation.

- threshold:

  Classification threshold.

- bootstrap:

  Calibration bootstrap replicates.

- seed:

  Deterministic seed.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_transportability_report` object.
