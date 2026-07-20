# Binary classification metrics

Binary classification metrics

## Usage

``` r
gazepoint_classification_metrics(
  truth,
  probability,
  predicted = NULL,
  positive = NULL,
  threshold = 0.5
)
```

## Arguments

- truth:

  Observed binary outcome values.

- probability:

  Predicted positive-class probabilities.

- predicted:

  Optional predicted classes.

- positive:

  Label representing the positive class.

- threshold:

  Probability threshold used for class predictions.
