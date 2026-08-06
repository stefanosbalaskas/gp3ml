# Evaluate named missingness-sensitivity scenarios

Evaluate named missingness-sensitivity scenarios

## Usage

``` r
evaluate_gazepoint_missingness_sensitivity(scenarios, evaluator, ...)
```

## Arguments

- scenarios:

  Named list of scenario objects.

- evaluator:

  Function called as `evaluator(scenario = scenario, name = name, ...)`.

- ...:

  Additional evaluator arguments.

## Value

A `gp3ml_stability_evaluation`.
