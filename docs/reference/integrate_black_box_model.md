# Integrate a controlled black-box model engine

Integrate a controlled black-box model engine

## Usage

``` r
integrate_black_box_model(
  name,
  fit_fun,
  predict_fun,
  supports = c("classification", "regression"),
  probability = TRUE,
  metadata = list(),
  safety_declaration
)
```

## Arguments

- name:

  Unique name for the custom engine.

- fit_fun:

  Function that fits the custom engine.

- predict_fun:

  Function that generates predictions.

- supports:

  Task types supported by the engine.

- probability:

  Whether classification probabilities are supported.

- metadata:

  Optional engine metadata.

- safety_declaration:

  Named logical safety declarations.

## Value

A controlled `gp3ml_engine` object containing the custom fit and
prediction functions, supported task types, metadata, and explicit
safety declarations.

## Examples

``` r
custom_fit <- function(x, y, task, args) {
  training_data <- data.frame(
    .outcome = y,
    x,
    check.names = FALSE
  )
  stats::glm(
    .outcome ~ .,
    data = training_data,
    family = stats::binomial()
  )
}
custom_predict <- function(fit, newdata, type, task, ...) {
  as.numeric(stats::predict(
    fit,
    newdata = as.data.frame(newdata),
    type = "response"
  ))
}
engine <- integrate_black_box_model(
  name = "custom_glm",
  fit_fun = custom_fit,
  predict_fun = custom_predict,
  supports = "classification",
  probability = TRUE,
  safety_declaration = list(
    prohibited_uses_acknowledged = TRUE,
    prediction_time_inputs_only = TRUE,
    group_aware_evaluation_required = TRUE
  )
)
engine$name
#> [1] "custom_glm"
engine$supports
#> [1] "classification"
engine$probability
#> [1] TRUE
engine$safety_declaration
#> $prohibited_uses_acknowledged
#> [1] TRUE
#> 
#> $prediction_time_inputs_only
#> [1] TRUE
#> 
#> $group_aware_evaluation_required
#> [1] TRUE
#> 
```
