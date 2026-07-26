
test_that("volatile artifact text is normalized deterministically", {
  x <- c(
    "Generated: 2026-07-25 23:26:03 UTC",
    "path=C:/Users/Test/AppData/Local/Temp/RtmpABC123/file1234567890",
    "<environment: 0x000001234ABCDEF0>"
  )
  normalized <- normalize_gazepoint_artifact_text(x)
  expect_match(normalized[[1L]], "<timestamp>", fixed = TRUE)
  expect_true(
    grepl("<TEMP_PATH>", normalized[[2L]], fixed = TRUE) ||
      grepl("<RTMP>", normalized[[2L]], fixed = TRUE)
  )
  expect_match(normalized[[3L]], "<ADDRESS>", fixed = TRUE)
})

test_that("reproducible-output option is restored", {
  old <- getOption("gp3ml.reproducible_examples", NULL)
  value <- with_gazepoint_reproducible_output(.gp3ml_timestamp())
  expect_identical(value, "<timestamp>")
  expect_identical(getOption("gp3ml.reproducible_examples", NULL), old)
})

test_that("artifact audit identifies volatile generated output", {
  path <- tempfile(fileext = ".md")
  on.exit(unlink(path), add = TRUE)
  writeLines("Generated: 2026-07-25 23:26:03 UTC", path)
  audit <- audit_gazepoint_reproducibility(path)
  expect_s3_class(audit, "gp3ml_reproducibility_audit")
  expect_identical(audit$status, "review")
  expect_gt(nrow(audit$findings), 0L)
})
