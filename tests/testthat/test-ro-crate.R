test_that("RO-Crate-oriented export validates its hashes", {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("openssl")
  td <- tempfile("crate-")
  dir.create(td)
  src <- file.path(td, "example.txt")
  writeLines("deterministic evidence", src)
  out <- file.path(td, "crate")
  crate <- write_gazepoint_ro_crate(
    out, files=src, name="Example gp3ml research object",
    description="Synthetic research artifact.",
    creator_name="Test Author", copy_files=TRUE
  )
  expect_s3_class(crate, "gp3ml_ro_crate")
  expect_identical(validate_gazepoint_ro_crate(crate)$status, "pass")
})
