test_that("governed thresholds require explicit candidates and remain deterministic", {
  truth <- factor(c("pass","review","pass","review","pass","review"),
                  levels=c("pass","review"))
  p <- c(.1,.8,.3,.7,.4,.9)
  ev <- evaluate_gazepoint_thresholds(
    truth, p, positive="review", thresholds=c(.3,.5,.7)
  )
  expect_s3_class(ev, "gp3ml_threshold_evaluation")
  rule <- select_gazepoint_threshold(
    ev, metric="balanced_accuracy", direction="maximize",
    generalization_target="new_participants",
    scientific_justification="Use balanced discrimination for predefined recording-quality review status."
  )
  expect_s3_class(rule, "gp3ml_decision_rule")
  expect_identical(validate_gazepoint_decision_rule(rule, TRUE)$status, "pass")
  decision <- apply_gazepoint_decision_rule(rule, p, "review", "pass")
  expect_length(decision, length(p))
})
