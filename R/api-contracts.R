
.gp3ml_contract_baseline_exports <- c("apply_gazepoint_calibrator", "assert_gp3ml_use_case", "assess_gazepoint_calibration", "audit_gazepoint_group_folds", "audit_gazepoint_ml_leakage", "audit_gazepoint_nested_resampling", "bake_gazepoint_preprocessor", "bootstrap_gazepoint_metrics", "bootstrap_gazepoint_metrics_by_unit", "collect_gazepoint_fold_predictions", "compare_gazepoint_models", "create_external_validation_report", "create_gazepoint_feature_manifest", "create_gazepoint_group_folds", "create_gazepoint_model_card", "create_gazepoint_nested_folds", "create_gazepoint_release_evidence", "create_gazepoint_release_model_card", "create_gazepoint_reproducibility_report", "create_gazepoint_synthetic_manifest", "create_gazepoint_synthetic_task", "create_gazepoint_tuning_grid", "declare_gazepoint_external_dataset", "declare_gazepoint_task", "diagnose_gazepoint_group_folds", "evaluate_external_validation", "evaluate_gazepoint_external_transportability", "evaluate_gazepoint_group_folds", "evaluate_gazepoint_nested_resampling", "fit_gazepoint_calibrator", "fit_gazepoint_deep_model", "fit_gazepoint_model", "fit_gazepoint_preprocessor", "gazepoint_classification_metrics", "gazepoint_performance_metrics", "gazepoint_regression_metrics", "gp3ml_available_engines", "gp3ml_prohibited_uses", "integrate_black_box_model", "select_gazepoint_model", "simulate_gazepoint_governed_data", "split_gazepoint_ml_data", "summarize_gazepoint_resample_performance", "summarize_gazepoint_resample_uncertainty", "train_gazepoint_classifier", "tune_gazepoint_model", "validate_gazepoint_feature_manifest", "validate_gazepoint_fold_diagnostics", "validate_gazepoint_group_folds", "validate_gazepoint_ml_roles", "validate_gazepoint_ml_split", "validate_gazepoint_model_tuning", "validate_gazepoint_nested_evaluation", "validate_gazepoint_nested_folds", "validate_gazepoint_resample_evaluation", "validate_gazepoint_target_uncertainty", "validate_gazepoint_transportability", "write_external_validation_report", "write_gazepoint_feature_manifest_csv", "write_gazepoint_fold_diagnostics_csv", "write_gazepoint_group_folds_csv", "write_gazepoint_ml_leakage_audit_csv", "write_gazepoint_ml_split_csv", "write_gazepoint_model_card", "write_gazepoint_model_tuning", "write_gazepoint_nested_evaluation", "write_gazepoint_release_model_card", "write_gazepoint_reproducibility_report", "write_gazepoint_resample_evaluation", "write_gazepoint_target_uncertainty", "write_gazepoint_transportability_report")
.gp3ml_contract_baseline_classes <- c("gazepoint_feature_manifest_validation", "gazepoint_fold_diagnostics", "gazepoint_fold_diagnostics_validation", "gazepoint_group_folds", "gazepoint_group_folds_audit", "gazepoint_group_folds_validation", "gazepoint_ml_leakage_audit", "gazepoint_ml_split", "gazepoint_ml_split_validation", "gp3ml_calibration_assessment", "gp3ml_external_dataset_declaration", "gp3ml_external_validation", "gp3ml_metric_uncertainty", "gp3ml_model", "gp3ml_model_card", "gp3ml_model_selection", "gp3ml_model_tuning", "gp3ml_model_tuning_validation", "gp3ml_nested_evaluation", "gp3ml_nested_evaluation_validation", "gp3ml_nested_folds", "gp3ml_nested_folds_validation", "gp3ml_nested_resampling_audit", "gp3ml_preprocessor", "gp3ml_release_evidence", "gp3ml_release_model_card", "gp3ml_reproducibility_report", "gp3ml_resample_evaluation", "gp3ml_resample_evaluation_validation", "gp3ml_resample_performance_summary", "gp3ml_resample_uncertainty", "gp3ml_role_validation", "gp3ml_target_uncertainty", "gp3ml_task", "gp3ml_transportability_report", "gp3ml_transportability_validation", "gp3ml_tuning_grid", "gp3ml_uncertainty_validation")

.gp3ml_contract_experimental_exports <- c(
  "gp3ml_api_contracts",
  "gp3ml_object_schema",
  "validate_gp3ml_object_contract",
  "audit_gp3ml_api_stability",
  "write_gp3ml_api_contracts",
  "gp3ml_interop_contracts",
  "create_gazepoint_handoff",
  "validate_gazepoint_handoff",
  "combine_gazepoint_handoffs",
  "as_gp3ml_data",
  "normalize_gazepoint_artifact_text",
  "audit_gazepoint_reproducibility",
  "write_gazepoint_reproducibility_audit",
  "with_gazepoint_reproducible_output",
  "gp3ml_engine_capabilities",
  "assert_gp3ml_engine_available",
  "simulate_gazepoint_research_handoffs",
  "validate_gazepoint_research_bundle"
)

#' gp3ml public API contracts
#'
#' Returns the package's explicit compatibility contract for the public API.
#' APIs present in version 0.2.0 are treated as stable within the 0.2.x line.
#' New APIs introduced by the current development milestone are marked
#' experimental until promoted by a later release decision.
#'
#' @return A `gp3ml_api_contract_registry` object.
#' @export
gp3ml_api_contracts <- function() {
  current <- sort(getNamespaceExports("gp3ml"))
  declared <- sort(unique(c(
    .gp3ml_contract_baseline_exports,
    .gp3ml_contract_experimental_exports
  )))

  exports <- data.frame(
    name = declared,
    stability = ifelse(
      declared %in% .gp3ml_contract_baseline_exports,
      "stable",
      "experimental"
    ),
    present = declared %in% current,
    stringsAsFactors = FALSE
  )

  classes <- data.frame(
    class = .gp3ml_contract_baseline_classes,
    stability = "stable",
    schema_policy = "additive_only_within_minor_line",
    stringsAsFactors = FALSE
  )

  policy <- data.frame(
    contract = c(
      "exported_function_name",
      "public_s3_class",
      "function_formals",
      "named_return_components"
    ),
    stable_rule = c(
      "No removal or rename within the 0.2.x line.",
      "No removal or rename within the 0.2.x line.",
      "Existing arguments retain meaning; new arguments require defaults.",
      "Existing named components retain meaning; additive components are allowed."
    ),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      contract_version = "0.3-development",
      package_version = tryCatch(
        as.character(utils::packageVersion("gp3ml")),
        error = function(e) "development"
      ),
      exports = exports,
      classes = classes,
      policy = policy
    ),
    class = "gp3ml_api_contract_registry"
  )
}

#' Describe the schema of a gp3ml object
#'
#' @param x Object to inspect.
#' @param recursive Whether to include one level of nested named-list components.
#'
#' @return A data frame describing component names, classes, storage types,
#' lengths, and dimensions.
#' @export
gp3ml_object_schema <- function(x, recursive = FALSE) {
  describe <- function(value, path) {
    cls <- class(value)
    data.frame(
      component = path,
      class = if (length(cls)) paste(cls, collapse = "/") else "",
      typeof = typeof(value),
      length = length(value),
      nrow = if (is.data.frame(value) || is.matrix(value)) nrow(value) else NA_integer_,
      ncol = if (is.data.frame(value) || is.matrix(value)) ncol(value) else NA_integer_,
      stringsAsFactors = FALSE
    )
  }

  if (!is.list(x) || is.data.frame(x)) {
    return(describe(x, "."))
  }

  nm <- names(x)
  if (is.null(nm)) nm <- rep("", length(x))
  out <- lapply(seq_along(x), function(i) {
    path <- if (nzchar(nm[[i]])) nm[[i]] else paste0("[[", i, "]]")
    rows <- list(describe(x[[i]], path))
    if (isTRUE(recursive) && is.list(x[[i]]) && !is.data.frame(x[[i]]) &&
        length(x[[i]]) && !is.null(names(x[[i]]))) {
      rows <- c(rows, lapply(seq_along(x[[i]]), function(j) {
        describe(x[[i]][[j]], paste0(path, "$", names(x[[i]])[[j]]))
      }))
    }
    do.call(rbind, rows)
  })
  result <- do.call(rbind, out)
  row.names(result) <- NULL
  result
}

#' Validate an object against the gp3ml public-object contract
#'
#' @param x A gp3ml object.
#' @param registry Contract registry from `gp3ml_api_contracts()`.
#'
#' @return A `gp3ml_object_contract_validation` object.
#' @export
validate_gp3ml_object_contract <- function(x, registry = gp3ml_api_contracts()) {
  object_classes <- class(x)
  registered <- intersect(object_classes, registry$classes$class)

  named_list <- is.list(x) && !is.data.frame(x)
  component_names <- if (named_list) names(x) else character()
  names_valid <- !named_list || (
    !is.null(component_names) &&
      length(component_names) == length(x) &&
      all(nzchar(component_names)) &&
      !anyDuplicated(component_names)
  )

  checks <- data.frame(
    check = c(
      "registered_public_class",
      "named_components",
      "schema_observable"
    ),
    status = c(
      if (length(registered)) "pass" else "review",
      if (names_valid) "pass" else "fail",
      "pass"
    ),
    detail = c(
      if (length(registered)) paste(registered, collapse = ", ") else
        "Class is not in the stable 0.2.0 public-class registry.",
      if (names_valid) "Named components are structurally valid." else
        "List-like public objects require unique non-empty component names.",
      "Schema can be represented by gp3ml_object_schema()."
    ),
    stringsAsFactors = FALSE
  )

  overall <- if (any(checks$status == "fail")) {
    "fail"
  } else if (any(checks$status == "review")) {
    "review"
  } else {
    "pass"
  }

  structure(
    list(
      status = overall,
      class = object_classes,
      checks = checks,
      schema = gp3ml_object_schema(x, recursive = TRUE)
    ),
    class = "gp3ml_object_contract_validation"
  )
}

#' Audit gp3ml API stability
#'
#' @param registry Contract registry.
#'
#' @return A `gp3ml_api_stability_audit` object.
#' @export
audit_gp3ml_api_stability <- function(registry = gp3ml_api_contracts()) {
  current <- sort(getNamespaceExports("gp3ml"))
  stable <- sort(registry$exports$name[registry$exports$stability == "stable"])
  experimental <- sort(registry$exports$name[registry$exports$stability == "experimental"])

  missing_stable <- setdiff(stable, current)
  unexpected <- setdiff(current, c(stable, experimental))

  current_print_methods <- utils::methods("print")
  current_public_classes <- sort(unique(sub(
    "^print\\.",
    "",
    grep("^print\\.(gazepoint_|gp3ml_)", current_print_methods, value = TRUE)
  )))
  missing_classes <- setdiff(registry$classes$class, current_public_classes)
  missing_classes <- setdiff(missing_classes, c(
    "gp3ml_engine",
    "gp3ml_external_validation_report"
  ))

  checks <- data.frame(
    check = c(
      "stable_exports_present",
      "declared_exports_only",
      "stable_public_classes_present"
    ),
    status = c(
      if (!length(missing_stable)) "pass" else "fail",
      if (!length(unexpected)) "pass" else "review",
      if (!length(missing_classes)) "pass" else "fail"
    ),
    n_issues = c(
      length(missing_stable),
      length(unexpected),
      length(missing_classes)
    ),
    stringsAsFactors = FALSE
  )

  overall <- if (any(checks$status == "fail")) {
    "fail"
  } else if (any(checks$status == "review")) {
    "review"
  } else {
    "pass"
  }

  diff <- data.frame(
    type = c(
      rep("missing_stable_export", length(missing_stable)),
      rep("unexpected_export", length(unexpected)),
      rep("missing_stable_class", length(missing_classes))
    ),
    name = c(missing_stable, unexpected, missing_classes),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      status = overall,
      checks = checks,
      differences = diff,
      registry = registry
    ),
    class = "gp3ml_api_stability_audit"
  )
}

#' Write gp3ml API contracts
#'
#' @param registry Contract registry.
#' @param directory Destination directory.
#' @param prefix File prefix.
#' @param overwrite Whether existing files may be replaced.
#'
#' @return Named character vector of written paths.
#' @export
write_gp3ml_api_contracts <- function(
  registry = gp3ml_api_contracts(),
  directory = ".",
  prefix = "gp3ml_api_contracts",
  overwrite = FALSE
) {
  if (!inherits(registry, "gp3ml_api_contract_registry")) {
    .gp3ml_stop("`registry` must be created by gp3ml_api_contracts().")
  }
  .gp3ml_write_tables(
    list(
      exports = registry$exports,
      classes = registry$classes,
      policy = registry$policy
    ),
    directory = directory,
    prefix = prefix,
    overwrite = overwrite
  )
}

#' @method print gp3ml_api_contract_registry
#' @export
print.gp3ml_api_contract_registry <- function(x, ...) {
  cat(
    " gp3ml API contract registry: ",
    sum(x$exports$stability == "stable"),
    " stable exports, ",
    sum(x$exports$stability == "experimental"),
    " experimental exports, ",
    nrow(x$classes),
    " stable public classes\n",
    sep = ""
  )
  invisible(x)
}

#' @method print gp3ml_object_contract_validation
#' @export
print.gp3ml_object_contract_validation <- function(x, ...) {
  cat(" gp3ml object contract: ", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' @method print gp3ml_api_stability_audit
#' @export
print.gp3ml_api_stability_audit <- function(x, ...) {
  cat(" gp3ml API stability audit: ", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' Plot a gp3ml API stability audit
#'
#' @param x A `gp3ml_api_stability_audit`.
#' @param ... Additional graphical parameters.
#'
#' @method plot gp3ml_api_stability_audit
#' @export
plot.gp3ml_api_stability_audit <- function(x, ...) {
  if (!inherits(x, "gp3ml_api_stability_audit")) {
    .gp3ml_stop("`x` must be a gp3ml API stability audit.")
  }
  values <- x$checks$n_issues
  names(values) <- x$checks$check
  graphics::barplot(
    values,
    las = 2,
    ylab = "Issues",
    main = paste("gp3ml API stability:", x$status),
    ...
  )
  invisible(x)
}
