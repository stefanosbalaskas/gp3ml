test_that("seed stability accepts explicit evaluator", {
  x <- evaluate_gazepoint_seed_stability(
    seeds=1:3,
    evaluator=function(seed) c(metric=0.8 + seed/1000)
  )
  expect_s3_class(x, "gp3ml_stability_evaluation")
  audit <- audit_gazepoint_model_robustness(seed_stability=x)
  expect_s3_class(audit, "gp3ml_model_robustness_audit")
})
