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
