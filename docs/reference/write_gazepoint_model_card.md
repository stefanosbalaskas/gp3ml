# Write a model card

Write a model card

## Usage

``` r
write_gazepoint_model_card(
  card,
  path,
  format = c("markdown", "json"),
  overwrite = FALSE
)
```

## Arguments

- card:

  A `gp3ml_model_card` object.

- path:

  Destination file path.

- format:

  Output format: Markdown or JSON.

- overwrite:

  Whether an existing file may be replaced.

## Value

The destination path, returned invisibly after the model card is
written.

## Examples

``` r
training_data <- data.frame(
  participant_id = rep(sprintf("P%02d", 1:12), each = 2),
  trial_id = sprintf("T%02d", 1:24),
  stimulus_id = rep(c("S01", "S02"), 12),
  fixation_duration = 180 + seq_len(24),
  pupil_change = sin(seq_len(24) / 3),
  stringsAsFactors = FALSE
)
training_data$quality_status <- factor(
  c(
    "pass", "review", "pass", "review", "review", "pass",
    "review", "pass", "pass", "review", "review", "pass",
    "review", "pass", "review", "pass", "pass", "review",
    "pass", "review", "review", "pass", "pass", "review"
  ),
  levels = c("pass", "review")
)
task <- declare_gazepoint_task(
  data = training_data,
  outcome = "quality_status",
  purpose = "Predict predefined recording-quality review status",
  task_type = "classification",
  unit_id = "trial_id",
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants",
  positive = "review"
)
model <- train_gazepoint_classifier(
  data = training_data,
  task = task,
  predictors = c("fixation_duration", "pupil_change"),
  engine = "glm",
  seed = 101L
)
card <- create_gazepoint_model_card(
  model = model,
  intended_use = paste(
    "Support manual review of predefined",
    "recording-quality status"
  ),
  limitations = "Synthetic example for documentation."
)
output <- tempfile(fileext = ".md")
write_gazepoint_model_card(
  card = card,
  path = output,
  format = "markdown"
)
file.exists(output)
#> [1] TRUE
unlink(output)
```
