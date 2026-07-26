
test_that("API contract registry protects the 0.2.0 surface", {
  registry <- gp3ml_api_contracts()
  expect_s3_class(registry, "gp3ml_api_contract_registry")
  expect_true(all(registry$exports$present))
  expect_true(any(registry$exports$stability == "stable"))
  expect_true(any(registry$exports$stability == "experimental"))

  audit <- audit_gp3ml_api_stability(registry)
  expect_s3_class(audit, "gp3ml_api_stability_audit")
  expect_identical(audit$status, "pass")
  expect_equal(nrow(audit$differences), 0L)
})

test_that("object schemas are deterministic and inspectable", {
  x <- structure(
    list(outcome = "assigned_condition", purpose = "synthetic"),
    class = "gp3ml_task"
  )
  schema <- gp3ml_object_schema(x, recursive = TRUE)
  expect_true(all(c("component", "class", "typeof", "length") %in% names(schema)))

  validation <- validate_gp3ml_object_contract(x)
  expect_s3_class(validation, "gp3ml_object_contract_validation")
  expect_identical(validation$status, "pass")
})
