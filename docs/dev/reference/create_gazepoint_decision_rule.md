# Create a governed classification decision rule

Create a governed classification decision rule

## Usage

``` r
create_gazepoint_decision_rule(
  metric,
  direction = c("maximize", "minimize"),
  threshold = NULL,
  threshold_origin = c("predeclared", "training", "inner_resampling"),
  cost_false_positive = 1,
  cost_false_negative = 1,
  abstention_allowed = FALSE,
  abstention_interval = NULL,
  calibration_source = "none",
  training_partition = "analysis",
  generalization_target,
  scientific_justification
)
```

## Arguments

- metric:

  Metric used to justify the threshold.

- direction:

  Either `"maximize"` or `"minimize"`.

- threshold:

  Optional probability threshold. Leave `NULL` until selected.

- threshold_origin:

  Origin of the threshold.

- cost_false_positive:

  Non-negative false-positive cost.

- cost_false_negative:

  Non-negative false-negative cost.

- abstention_allowed:

  Whether abstention is permitted.

- abstention_interval:

  Optional length-two probability interval. Probabilities inside the
  interval are labelled as abstentions.

- calibration_source:

  Description of the calibration source.

- training_partition:

  Description of the data partition used to determine the threshold.

- generalization_target:

  Declared generalization target.

- scientific_justification:

  Explicit scientific justification.

## Value

A `gp3ml_decision_rule`.
