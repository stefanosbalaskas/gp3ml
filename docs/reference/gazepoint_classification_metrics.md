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

## Value

A one-row data frame containing the sample size, threshold,
class-performance measures, discrimination metrics, Brier score, and log
loss.

## Examples

``` r
truth <- factor(
  rep(c("pass", "review"), 6),
  levels = c("pass", "review")
)
probability <- c(
  0.20, 0.70, 0.60, 0.55, 0.30, 0.80,
  0.65, 0.45, 0.40, 0.75, 0.50, 0.60
)
predicted <- factor(
  ifelse(probability >= 0.5, "review", "pass"),
  levels = levels(truth)
)
gazepoint_classification_metrics(
  truth = truth,
  probability = probability,
  predicted = predicted,
  positive = "review"
)
#>    n threshold  accuracy balanced_accuracy sensitivity specificity precision
#> 1 12       0.5 0.6666667         0.6666667   0.8333333         0.5     0.625
#>      recall        f1       mcc   roc_auc    pr_auc     brier  log_loss
#> 1 0.8333333 0.7142857 0.3535534 0.8194444 0.8412698 0.1816667 0.5437146
```
