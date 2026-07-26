
test_that("handoffs validate and combine without duplicating preprocessing", {
  keys <- c("participant_id", "trial_id", "stimulus_id")

  a <- data.frame(
    participant_id = c("P01", "P02"),
    trial_id = c("T01", "T02"),
    stimulus_id = c("S01", "S02"),
    outcome = c("A", "B"),
    gaze_feature = c(1.1, 1.4),
    stringsAsFactors = FALSE
  )
  b <- data.frame(
    participant_id = c("P01", "P02"),
    trial_id = c("T01", "T02"),
    stimulus_id = c("S01", "S02"),
    signal_valid_prop = c(0.95, 0.97),
    stringsAsFactors = FALSE
  )

  h1 <- create_gazepoint_handoff(
    a, "gp3tools", keys = keys,
    outcome = "outcome", predictors = "gaze_feature"
  )
  h2 <- create_gazepoint_handoff(
    b, "gpbiometrics", keys = keys,
    predictors = "signal_valid_prop"
  )

  expect_identical(validate_gazepoint_handoff(h1)$status, "pass")
  expect_identical(validate_gazepoint_handoff(h2)$status, "pass")

  bundle <- combine_gazepoint_handoffs(list(gaze = h1, bio = h2))
  expect_s3_class(bundle, "gp3ml_handoff_bundle")
  expect_equal(nrow(as_gp3ml_data(bundle)), 2L)
  expect_true(all(c("gaze_feature", "signal_valid_prop") %in% names(bundle$data)))
})

test_that("duplicate join keys fail handoff validation", {
  data <- data.frame(
    participant_id = c("P01", "P01"),
    trial_id = c("T01", "T01"),
    stimulus_id = c("S01", "S01"),
    x = 1:2
  )
  h <- create_gazepoint_handoff(
    data,
    "custom",
    keys = c("participant_id", "trial_id", "stimulus_id"),
    predictors = "x"
  )
  expect_identical(validate_gazepoint_handoff(h)$status, "fail")
})
