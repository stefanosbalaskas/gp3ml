testthat::test_that("synthetic participant leakage audit preserves disjoint participant holdout", {
  script <- system.file("research", "october_2026_participant_leakage.R",
                        package = "gp3ml")
  testthat::expect_true(nzchar(script))
  env <- new.env(parent = baseenv())
  sys.source(script, envir = env)
  x <- env$gp3ml_october_leakage_audit(repeats = 12L, seed = 20261022L)
  testthat::expect_equal(nrow(x), 24L)
  testthat::expect_equal(sort(unique(x$split)),
                         c("observation", "participant"))
  testthat::expect_true(all(x$shared_participants[x$split == "participant"] == 0L))
  testthat::expect_true(all(x$heldout_accuracy >= 0 & x$heldout_accuracy <= 1))
  testthat::expect_gt(
    mean(x$heldout_accuracy[x$split == "observation"]),
    mean(x$heldout_accuracy[x$split == "participant"]))
  testthat::expect_identical(x, env$gp3ml_october_leakage_audit(
    repeats = 12L, seed = 20261022L))
})
