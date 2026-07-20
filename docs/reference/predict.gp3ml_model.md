# Predict from a gp3ml model

Predict from a gp3ml model

## Usage

``` r
# S3 method for class 'gp3ml_model'
predict(
  object,
  newdata,
  type = c("response", "probability", "class", "link"),
  ...
)
```

## Arguments

- object:

  A fitted `gp3ml_model` object.

- newdata:

  New data containing the required predictors.

- type:

  Requested prediction type.

- ...:

  Additional arguments passed to custom prediction methods.
