# Evaluate nested grouped resampling with inner governed tuning

Evaluate nested grouped resampling with inner governed tuning

## Usage

``` r
evaluate_gazepoint_nested_resampling(
  nested_folds,
  task,
  tuning_grid,
  selection_metric,
  direction,
  predictors = NULL,
  minimum_success_prop = 0.8,
  tie_breakers = NULL,
  selection_rationale = .gp3ml_nested_selection_rationale_default,
  seed = 1L,
  keep_models = FALSE,
  continue_on_error = TRUE
)

# S3 method for class 'gp3ml_nested_evaluation'
print(x, ...)
```

## Arguments

- nested_folds:

  A `gp3ml_nested_folds` object.

- task:

  Governed task.

- tuning_grid:

  Explicit tuning grid.

- selection_metric:

  Explicit inner selection metric.

- direction:

  Explicit selection direction.

- predictors:

  Optional predictors.

- minimum_success_prop:

  Minimum inner-fold success proportion.

- tie_breakers:

  Optional secondary metrics.

- selection_rationale:

  Human rationale recorded for each outer fold.

- seed:

  Base deterministic seed.

- keep_models:

  Whether outer fitted models are retained.

- continue_on_error:

  Whether failed outer folds remain in the result.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_nested_evaluation` object retaining inner tuning results,
selections, outer predictions, metrics, and failures.
