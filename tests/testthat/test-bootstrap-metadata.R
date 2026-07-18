test_that("package metadata identifies the development bootstrap", {
  if (requireNamespace("gp3ml", quietly = TRUE)) {
    metadata <- utils::packageDescription("gp3ml")
    package_name <- metadata$Package
    package_version <- metadata$Version
  } else {
    description_path <- testthat::test_path(
      "..",
      "..",
      "DESCRIPTION"
    )

    expect_true(file.exists(description_path))

    metadata <- read.dcf(description_path)
    package_name <- unname(metadata[1, "Package"])
    package_version <- unname(metadata[1, "Version"])
  }

  expect_identical(package_name, "gp3ml")
  expect_identical(package_version, "0.0.0.9000")
})
