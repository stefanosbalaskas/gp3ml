# Audit abstention decisions

Audit abstention decisions

## Usage

``` r
audit_gazepoint_abstention(truth, decision, abstain_label = ".abstain")
```

## Arguments

- truth:

  Observed binary outcome.

- decision:

  Decisions returned by
  [`apply_gazepoint_decision_rule()`](https://stefanosbalaskas.github.io/gp3ml/dev/reference/apply_gazepoint_decision_rule.md).

- abstain_label:

  Abstention label.

## Value

A `gp3ml_abstention_audit`.
