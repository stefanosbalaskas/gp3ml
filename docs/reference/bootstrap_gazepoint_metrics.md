# Bootstrap uncertainty intervals for performance metrics

Bootstrap uncertainty intervals for performance metrics

## Usage

``` r
bootstrap_gazepoint_metrics(
  task,
  truth,
  prediction = NULL,
  probability = NULL,
  threshold = 0.5,
  bootstrap = 1000L,
  conf_level = 0.95,
  seed = 1L
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

- bootstrap:

  Number of bootstrap replicates.

- conf_level:

  Confidence level for percentile intervals.

- seed:

  Deterministic random seed.
