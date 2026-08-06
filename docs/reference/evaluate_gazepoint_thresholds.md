# Evaluate explicit classification thresholds

Evaluate explicit classification thresholds

## Usage

``` r
evaluate_gazepoint_thresholds(
  truth,
  probability,
  positive,
  thresholds,
  cost_false_positive = 1,
  cost_false_negative = 1
)
```

## Arguments

- truth:

  Observed binary outcome.

- probability:

  Probability of the positive class.

- positive:

  Positive class label.

- thresholds:

  Explicit candidate thresholds.

- cost_false_positive:

  False-positive cost.

- cost_false_negative:

  False-negative cost.

## Value

A `gp3ml_threshold_evaluation`.
