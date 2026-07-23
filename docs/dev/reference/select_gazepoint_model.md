# Select a governed candidate using an explicit metric and direction

This function records a reviewable decision. It does not refit a model
and refuses accuracy as the sole primary metric.

## Usage

``` r
select_gazepoint_model(
  x,
  metric,
  direction,
  minimum_success_prop = 0.8,
  tie_breakers = NULL,
  rationale
)

# S3 method for class 'gp3ml_model_selection'
print(x, ...)
```

## Arguments

- x:

  A `gp3ml_model_tuning` object.

- metric:

  Explicit primary metric.

- direction:

  Explicit optimization direction.

- minimum_success_prop:

  Minimum successful-fold proportion.

- tie_breakers:

  Optional ordered secondary metric names.

- rationale:

  Required human-readable selection rationale.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_model_selection` object.
