test_that("all analytical-roadmap exports are callable", {
  required <- c(
    "simulate_gazepoint_governed_data",
    "create_gazepoint_synthetic_manifest",
    "create_gazepoint_synthetic_task",
    "evaluate_gazepoint_group_folds",
    "collect_gazepoint_fold_predictions",
    "summarize_gazepoint_resample_performance",
    "validate_gazepoint_resample_evaluation",
    "create_gazepoint_tuning_grid",
    "tune_gazepoint_model",
    "compare_gazepoint_models",
    "select_gazepoint_model",
    "validate_gazepoint_model_tuning",
    "write_gazepoint_model_tuning",
    "create_gazepoint_nested_folds",
    "audit_gazepoint_nested_resampling",
    "validate_gazepoint_nested_folds",
    "evaluate_gazepoint_nested_resampling",
    "validate_gazepoint_nested_evaluation",
    "bootstrap_gazepoint_metrics_by_unit",
    "summarize_gazepoint_resample_uncertainty",
    "validate_gazepoint_target_uncertainty",
    "declare_gazepoint_external_dataset",
    "evaluate_gazepoint_external_transportability",
    "validate_gazepoint_transportability",
    "create_gazepoint_release_model_card",
    "write_gazepoint_release_model_card",
    "create_gazepoint_release_evidence"
  )
  exports <- getNamespaceExports("gp3ml")
  expect_setequal(intersect(required, exports), required)
})
