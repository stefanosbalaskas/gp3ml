test_that(".gp3ml_bind_rows supports mixed empty and populated tables", {
  populated <- data.frame(
    fold_id = "Repeat01_Fold01",
    value = 1,
    stringsAsFactors = FALSE
  )

  result <- gp3ml:::.gp3ml_bind_rows(list(
    data.frame(),
    populated,
    data.frame()
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_named(result, c("fold_id", "value"))
  expect_identical(result$fold_id, "Repeat01_Fold01")
  expect_equal(result$value, 1)
})

test_that(".gp3ml_bind_rows supports entirely empty inputs", {
  result <- gp3ml:::.gp3ml_bind_rows(list(
    data.frame(),
    data.frame()
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that(".gp3ml_metric_long preserves reserved identifier names", {
  metrics <- data.frame(
    rmse = 0.25,
    n = 12L,
    stringsAsFactors = FALSE
  )

  result <- gp3ml:::.gp3ml_metric_long(
    metrics,
    identifiers = list(
      `repeat` = 1L,
      fold = 2L,
      fold_id = "Repeat01_Fold02"
    )
  )

  expect_true("repeat" %in% names(result))
  expect_false("repeat." %in% names(result))
  expect_identical(result[["repeat"]], 1L)
  expect_identical(result$fold, 2L)
  expect_identical(result$fold_id, "Repeat01_Fold02")
  expect_identical(result$metric, "rmse")
})
