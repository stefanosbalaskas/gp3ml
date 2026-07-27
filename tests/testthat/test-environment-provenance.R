test_that("environment capture is self-comparable", {
  x <- capture_gazepoint_environment(packages="gp3ml")
  y <- compare_gazepoint_environments(x, x)
  expect_s3_class(y, "gp3ml_environment_comparison")
  expect_identical(y$status, "pass")
})
test_that("environment self-comparison is fully classified and plot-safe", {

  x <- capture_gazepoint_environment(
    packages = "gp3ml"
  )

  y <- compare_gazepoint_environments(
    x,
    x
  )

  expect_identical(
    y$status,
    "pass"
  )

  expect_false(
    anyNA(
      c(
        y$packages$status,
        y$core$status
      )
    )
  )

  expect_true(
    all(
      y$core$status == "pass"
    )
  )

  expect_silent(
    plot(y)
  )
})
