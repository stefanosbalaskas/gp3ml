# Generalization-target-aligned bootstrap uncertainty

Resamples observations or declared clusters while preserving every row
that belongs to a sampled cluster. Repeated cluster draws duplicate all
associated rows. The returned object records the resampling unit and
must not be described as uncertainty for another unit.

## Usage

``` r
bootstrap_gazepoint_metrics_by_unit(
  task,
  truth,
  prediction = NULL,
  probability = NULL,
  participant_id = NULL,
  stimulus_id = NULL,
  unit = c("observation", "participant", "stimulus", "participant_and_stimulus"),
  bootstrap = 1000L,
  conf_level = 0.95,
  seed = 1L,
  threshold = 0.5,
  stratify_observations = TRUE
)

# S3 method for class 'gp3ml_target_uncertainty'
print(x, ...)
```

## Arguments

- task:

  Governed task.

- truth:

  Observed outcomes.

- prediction:

  Predicted classes or numeric outcomes.

- probability:

  Positive-class probabilities.

- participant_id:

  Participant identifiers for participant-based methods.

- stimulus_id:

  Stimulus identifiers for stimulus-based methods.

- unit:

  Resampling unit.

- bootstrap:

  Number of replicates.

- conf_level:

  Percentile interval level.

- seed:

  Deterministic seed.

- threshold:

  Classification threshold.

- stratify_observations:

  Whether the observation-level classification bootstrap preserves class
  counts.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_target_uncertainty` object.

## Examples

``` r
data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 404L)
task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
probability <- seq(0.15, 0.85, length.out = nrow(data))
prediction <- factor(
  ifelse(probability >= 0.5, "review", "pass"),
  levels = levels(data$quality_status)
)
uncertainty <- bootstrap_gazepoint_metrics_by_unit(
  task,
  truth = data$quality_status,
  prediction = prediction,
  probability = probability,
  participant_id = data$participant_id,
  unit = "participant",
  bootstrap = 20L,
  seed = 404L
)
uncertainty
#> <gp3ml_target_uncertainty>
#>   Unit: participant
#>   Target: new_participants
#>   Successful/failed replicates: 20/0
#>             metric  estimate       lower     upper successful_replicates
#>           accuracy 0.5416667  0.24895833 0.7322917                    20
#>  balanced_accuracy 0.5952381  0.25033152 0.7702083                    20
#>        sensitivity 0.6666667  0.19000000 1.0000000                    20
#>        specificity 0.5238095  0.16501637 0.7611012                    20
#>          precision 0.1666667  0.03392857 0.3375000                    20
#>             recall 0.6666667  0.19000000 1.0000000                    20
#>                 f1 0.2666667  0.13963964 0.4473404                    19
#>                mcc 0.1259882 -0.19287173 0.3484465                    20
#>            roc_auc 0.7222222  0.36368629 0.8982031                    20
#>             pr_auc 0.3016302  0.07021436 0.5809971                    20
#>              brier 0.2578191  0.18346537 0.3484199                    20
#>           log_loss 0.7160103  0.55069963 0.9149671                    20
```
