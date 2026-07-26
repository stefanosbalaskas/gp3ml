# Fit target-aware split-conformal calibration

This function provides conservative split-conformal calibration for
explicitly observed regression or binary classification outcomes. When a
grouped calibration unit is supplied, row scores are aggregated to the
maximum score within each calibration unit before the conformal quantile
is estimated. This records and respects the calibration unit but does
not claim distribution-free coverage under arbitrary dependence.

## Usage

``` r
fit_gazepoint_conformal(
  truth,
  prediction = NULL,
  probability = NULL,
  task_type = c("regression", "classification"),
  positive = NULL,
  level = 0.9,
  calibration_unit = c("observation", "participant", "stimulus", "participant_stimulus"),
  unit = NULL,
  generalization_target
)
```

## Arguments

- truth:

  Observed calibration outcomes.

- prediction:

  Numeric predictions for regression.

- probability:

  Positive-class probabilities for classification.

- task_type:

  `"regression"` or `"classification"`.

- positive:

  Positive class label for classification.

- level:

  Nominal coverage level.

- calibration_unit:

  Calibration unit.

- unit:

  Optional group identifier for grouped calibration.

- generalization_target:

  Declared generalization target.

## Value

A `gp3ml_conformal_fit`.
