test_that("cluster bootstrap records the actual resampling unit", {
  data <- simulate_gazepoint_governed_data(12L, 4L, 1L, 1501L)
  task <- create_gazepoint_synthetic_task(data, "recording_quality", "new_participants")
  probability <- seq(0.1, 0.9, length.out = nrow(data))
  prediction <- factor(
    ifelse(probability >= 0.5, "review", "pass"),
    levels = levels(data$quality_status)
  )
  participant <- bootstrap_gazepoint_metrics_by_unit(
    task,
    data$quality_status,
    prediction,
    probability,
    participant_id = data$participant_id,
    unit = "participant",
    bootstrap = 25L,
    seed = 1501L
  )
  expect_s3_class(participant, "gp3ml_target_uncertainty")
  expect_identical(participant$unit, "participant")
  expect_identical(participant$generalization_target, "new_participants")
  expect_equal(participant$successful_replicates + participant$failed_replicates, 25L)
  expect_match(participant$limitations, "Participant-cluster")
})

test_that("two-way bootstrap preserves metadata and variable replicate sizes", {
  data <- simulate_gazepoint_governed_data(10L, 4L, 1L, 1502L)
  task <- create_gazepoint_synthetic_task(
    data, "recording_quality", "new_participants_and_new_stimuli"
  )
  probability <- seq(0.15, 0.85, length.out = nrow(data))
  prediction <- factor(
    ifelse(probability >= 0.5, "review", "pass"),
    levels = levels(data$quality_status)
  )
  uncertainty <- bootstrap_gazepoint_metrics_by_unit(
    task,
    data$quality_status,
    prediction,
    probability,
    participant_id = data$participant_id,
    stimulus_id = data$stimulus_id,
    unit = "participant_and_stimulus",
    bootstrap = 20L,
    seed = 1502L
  )
  expect_identical(uncertainty$unit, "participant_and_stimulus")
  expect_true(all(uncertainty$replicate_sizes > 0L))
  expect_s3_class(validate_gazepoint_target_uncertainty(uncertainty), "gp3ml_uncertainty_validation")
})

test_that("fold-distribution uncertainty remains explicitly labelled", {
  fixture <- roadmap_fixture(seed = 1503L)
  evaluation <- evaluate_gazepoint_group_folds(
    fixture$folds, fixture$task, fixture$predictors, "glm", seed = 1503L
  )
  uncertainty <- summarize_gazepoint_resample_uncertainty(evaluation, "fold")
  expect_s3_class(uncertainty, "gp3ml_resample_uncertainty")
  expect_identical(uncertainty$unit, "fold")
  expect_match(uncertainty$limitations, "not a substitute")
})

test_that("regression cluster uncertainty uses explicit stimulus units", {
  data <- simulate_gazepoint_governed_data(12L, 5L, 1L, 1504L)
  task <- create_gazepoint_synthetic_task(data, "observed_duration", "new_stimuli")
  prediction <- data$observed_duration + rep(c(-0.1, 0.1), length.out = nrow(data))
  uncertainty <- bootstrap_gazepoint_metrics_by_unit(
    task,
    truth = data$observed_duration,
    prediction = prediction,
    stimulus_id = data$stimulus_id,
    unit = "stimulus",
    bootstrap = 20L,
    seed = 1504L
  )
  expect_identical(uncertainty$unit, "stimulus")
  expect_true(all(c("rmse", "mae") %in% uncertainty$intervals$metric))
})
