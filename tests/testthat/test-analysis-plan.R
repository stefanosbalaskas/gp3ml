test_that("analysis plans validate and hash when openssl is available", {
  plan <- declare_gazepoint_analysis_plan(
    research_question="Can predefined QC review status generalize to new participants?",
    scientific_purpose="Evaluate a predefined recording-quality review endpoint.",
    outcome="quality_status",
    outcome_definition="Observed predefined review status.",
    predictors=c("fixation_duration","pupil_change"),
    generalization_target="new_participants",
    grouping_variables="participant_id",
    eligible_population="Recorded study participants meeting protocol eligibility.",
    preprocessing_plan="Fit preprocessing inside each analysis fold.",
    candidate_models=c("glm","ranger"),
    primary_metric="balanced_accuracy",
    calibration_metric="brier",
    uncertainty_method="participant_cluster_bootstrap",
    threshold_policy="Select inside inner resampling.",
    seed_strategy="Predeclared deterministic seeds."
  )
  expect_identical(validate_gazepoint_analysis_plan(plan)$status, "pass")
  skip_if_not_installed("openssl")
  locked <- lock_gazepoint_analysis_plan(plan)
  expect_true(locked$locked)
  expect_match(locked$plan_hash, "^[0-9a-f]+$")
})
