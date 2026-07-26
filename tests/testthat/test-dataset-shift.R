test_that("dataset shift distinguishes numeric and categorical predictors", {
  d <- data.frame(x=1:20, g=rep(c("A","B"),10), stringsAsFactors=FALSE)
  e <- data.frame(x=11:30, g=rep(c("A","C"),10), stringsAsFactors=FALSE)
  audit <- audit_gazepoint_dataset_shift(d, e, c("x","g"))
  expect_s3_class(audit, "gp3ml_dataset_shift_audit")
  expect_equal(nrow(audit$findings), 2)
  expect_true(any(nzchar(audit$findings$novel_levels)))
})
