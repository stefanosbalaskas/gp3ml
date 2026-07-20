# Create an external-validation report object

Create an external-validation report object

## Usage

``` r
create_external_validation_report(
  validation,
  development_metrics = NULL,
  limitations = character()
)
```

## Arguments

- validation:

  A `gp3ml_external_validation` object.

- development_metrics:

  Optional development-sample metrics.

- limitations:

  Character vector describing report limitations.
