test_that("regression conformal intervals are deterministic", {
  truth <- c(1,2,3,4,5,6)
  pred <- c(1.1,1.8,2.9,4.2,5.2,5.8)
  fit <- fit_gazepoint_conformal(
    truth=truth, prediction=pred, task_type="regression",
    level=.8, calibration_unit="observation",
    generalization_target="new_trials_known_participants"
  )
  expect_s3_class(fit, "gp3ml_conformal_fit")
  expect_identical(validate_gazepoint_conformal(fit)$status, "pass")
  interval <- predict_gazepoint_interval(fit, c(2,4))
  expect_true(all(interval$lower <= interval$prediction))
  expect_true(all(interval$upper >= interval$prediction))
})

test_that("grouped calibration records units conservatively", {
  fit <- fit_gazepoint_conformal(
    truth=c(1,1.5,2,2.5),
    prediction=c(1,1.4,2.1,2.3),
    task_type="regression", level=.8,
    calibration_unit="participant",
    unit=c("P1","P1","P2","P2"),
    generalization_target="new_participants"
  )
  expect_equal(fit$n_calibration_units, 2)
})
