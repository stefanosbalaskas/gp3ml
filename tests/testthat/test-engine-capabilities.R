
test_that("engine capability audit covers every supported engine", {
  x <- gp3ml_engine_capabilities(check_keras_backend = FALSE)
  expect_s3_class(x, "gp3ml_engine_capabilities")
  expect_setequal(
    x$engine,
    c("glm", "lm", "ranger", "xgboost", "nnet", "keras3", "custom")
  )
  expect_true(x$package_available[x$engine == "glm"])
  expect_true(x$package_available[x$engine == "lm"])
  expect_true(x$package_available[x$engine == "custom"])
})

test_that("base engines pass availability assertions", {
  expect_true(assert_gp3ml_engine_available("glm"))
  expect_true(assert_gp3ml_engine_available("lm"))
})

test_that("unknown engines fail with a controlled error", {
  expect_error(
    assert_gp3ml_engine_available("not_an_engine"),
    "Unknown gp3ml engine"
  )
})
