# Select a threshold from a governed threshold evaluation

Select a threshold from a governed threshold evaluation

## Usage

``` r
select_gazepoint_threshold(
  evaluation,
  metric,
  direction = c("maximize", "minimize"),
  threshold_origin = c("inner_resampling", "training"),
  training_partition = "inner_resampling",
  generalization_target,
  scientific_justification,
  abstention_allowed = FALSE,
  abstention_interval = NULL
)
```

## Arguments

- evaluation:

  A `gp3ml_threshold_evaluation`.

- metric:

  Metric column to optimize.

- direction:

  `"maximize"` or `"minimize"`.

- threshold_origin:

  Must identify an analysis/training source.

- training_partition:

  Partition used to select the threshold.

- generalization_target:

  Declared target.

- scientific_justification:

  Explicit justification.

- abstention_allowed:

  Whether abstention is allowed.

- abstention_interval:

  Optional abstention interval.

## Value

A `gp3ml_decision_rule`.
