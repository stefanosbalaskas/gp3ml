test_that("governance profile never claims certification", {
  p <- create_gp3ml_governance_profile(
    evidence=list(task=structure(list(), class="gp3ml_task")),
    framework="ISO-42001-oriented"
  )
  expect_match(p$disclaimer, "not evidence", ignore.case=TRUE)
  audit <- audit_gp3ml_governance_profile(p)
  expect_s3_class(audit, "gp3ml_governance_profile_audit")
})
