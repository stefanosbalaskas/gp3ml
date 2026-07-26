# Apply a governed classification decision rule

Apply a governed classification decision rule

## Usage

``` r
apply_gazepoint_decision_rule(
  rule,
  probability,
  positive,
  negative,
  abstain_label = ".abstain"
)
```

## Arguments

- rule:

  A validated decision rule.

- probability:

  Positive-class probability.

- positive:

  Positive class label.

- negative:

  Negative class label.

- abstain_label:

  Label used for abstentions.

## Value

A factor of governed decisions.
