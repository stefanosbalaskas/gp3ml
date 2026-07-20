# Task-aware performance metrics

Task-aware performance metrics

## Usage

``` r
gazepoint_performance_metrics(
  task,
  truth,
  prediction = NULL,
  probability = NULL,
  threshold = 0.5
)
```

## Arguments

- task:

  A governed `gp3ml_task` object.

- truth:

  Observed outcome values.

- prediction:

  Predicted classes or numeric values.

- probability:

  Predicted positive-class probabilities.

- threshold:

  Probability threshold for classification.
