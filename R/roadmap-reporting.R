#' Create a release-ready governed model card
#'
#' Extends the existing model-card structure with explicit model-selection,
#' target-aligned uncertainty, nested-resampling, and transportability fields.
#'
#' @param model Fitted governed model.
#' @param intended_use Intended scientific use.
#' @param evaluation Grouped or nested evaluation.
#' @param selection Optional `gp3ml_model_selection`.
#' @param uncertainty Optional target-aligned uncertainty object.
#' @param calibration Optional calibration assessment.
#' @param feature_manifest Optional feature manifest.
#' @param transportability Optional transportability report.
#' @param limitations Required limitations.
#' @param ethical_review Optional ethical-review information.
#' @param deployment_status Deployment status; defaults to research review only.
#'
#' @return A `gp3ml_release_model_card`.
#' @export
create_gazepoint_release_model_card <- function(
    model,
    intended_use,
    evaluation = NULL,
    selection = NULL,
    uncertainty = NULL,
    calibration = NULL,
    feature_manifest = NULL,
    transportability = NULL,
    limitations,
    ethical_review = NULL,
    deployment_status = "research_review_only") {
  if (!inherits(model, "gp3ml_model")) .gp3ml_stop("`model` must be a fitted gp3ml model.")
  if (missing(limitations) || !length(limitations) || any(!nzchar(trimws(limitations)))) {
    .gp3ml_stop("At least one explicit limitation is required.")
  }
  if (!is.null(selection) && !inherits(selection, "gp3ml_model_selection")) {
    .gp3ml_stop("`selection` must be a `gp3ml_model_selection` object.")
  }
  if (!is.null(uncertainty) && !inherits(uncertainty, c("gp3ml_target_uncertainty", "gp3ml_resample_uncertainty"))) {
    .gp3ml_stop("`uncertainty` must be a target-aligned gp3ml uncertainty object.")
  }
  if (!is.null(transportability) && !inherits(transportability, "gp3ml_transportability_report")) {
    .gp3ml_stop("`transportability` must be a `gp3ml_transportability_report`.")
  }
  base <- create_gazepoint_model_card(
    model = model,
    intended_use = intended_use,
    evaluation = evaluation,
    calibration = calibration,
    feature_manifest = feature_manifest,
    external_validation = if (is.null(transportability)) NULL else transportability$validation,
    limitations = limitations,
    ethical_review = ethical_review
  )
  base$selection <- selection
  base$uncertainty <- uncertainty
  base$transportability <- transportability
  base$deployment_status <- deployment_status
  base$selection_procedure_recorded <- !is.null(selection)
  base$uncertainty_unit <- if (is.null(uncertainty)) NA_character_ else uncertainty$unit
  base$generalization_target <- model$task$generalization_target
  base$external_validation_status <- if (is.null(transportability)) "not_externally_validated" else transportability$status
  base$autonomous_selection <- FALSE
  class(base) <- c("gp3ml_release_model_card", "gp3ml_model_card")
  base
}

.gp3ml_release_card_metrics <- function(card) {
  if (inherits(card$evaluation, c("gp3ml_resample_evaluation", "gp3ml_nested_evaluation"))) {
    summary <- summarize_gazepoint_resample_performance(card$evaluation)
    return(summary$summary)
  }
  if (is.data.frame(card$evaluation)) return(card$evaluation)
  data.frame()
}

.gp3ml_release_card_selection <- function(selection) {
  if (is.null(selection)) return(data.frame())
  data.frame(
    candidate_id = selection$candidate_id,
    primary_metric = selection$primary_metric,
    direction = selection$direction,
    primary_value = selection$primary_value,
    minimum_success_prop = selection$minimum_success_prop,
    rationale = selection$rationale,
    autonomous_selection = selection$autonomous_selection,
    refit_performed = selection$refit_performed,
    stringsAsFactors = FALSE
  )
}

.gp3ml_release_card_uncertainty <- function(uncertainty) {
  if (is.null(uncertainty)) return(data.frame())
  if (inherits(uncertainty, "gp3ml_target_uncertainty")) return(uncertainty$intervals)
  uncertainty$summary
}

#' Write a release-ready governed model card
#'
#' @param card A `gp3ml_release_model_card`.
#' @param path Destination path.
#' @param format Markdown or JSON.
#' @param overwrite Whether an existing file may be replaced.
#'
#' @return The destination path, invisibly.
#' @export
write_gazepoint_release_model_card <- function(
    card,
    path,
    format = c("markdown", "json"),
    overwrite = FALSE) {
  if (!inherits(card, "gp3ml_release_model_card")) {
    .gp3ml_stop("`card` must be a `gp3ml_release_model_card`.")
  }
  format <- match.arg(format)
  if (file.exists(path) && !overwrite) .gp3ml_stop("File exists: %s.", path)
  if (format == "json") {
    if (!requireNamespace("jsonlite", quietly = TRUE)) .gp3ml_stop("Install `jsonlite` for JSON output.")
    jsonlite::write_json(
      .gp3ml_json_ready(card),
      path,
      pretty = TRUE,
      auto_unbox = TRUE,
      null = "null",
      na = "null"
    )
    return(invisible(path))
  }
  selection <- .gp3ml_release_card_selection(card$selection)
  uncertainty <- .gp3ml_release_card_uncertainty(card$uncertainty)
  transportability <- card$transportability
  lines <- c(
    paste0("# ", card$title), "",
    paste0("Generated: ", card$created_at), "",
    "## Intended use", "", card$intended_use, "",
    "## Governance contract", "",
    paste0("- Outcome: `", card$task$outcome, "`"),
    paste0("- Task type: `", card$task$task_type, "`"),
    paste0("- Generalization target: `", card$generalization_target, "`"),
    paste0("- Deployment status: `", card$deployment_status, "`"),
    "- Autonomous model selection: `FALSE`", "",
    "## Model", "",
    paste0("- Engine: `", card$engine, "`"),
    paste0("- Predictors: ", paste(sprintf("`%s`", card$predictors), collapse = ", ")),
    paste0("- Training rows: ", card$training_n),
    paste0("- Training hash: `", card$training_hash, "`"), "",
    "## Resampling performance", "",
    .gp3ml_markdown_table(.gp3ml_release_card_metrics(card)), "",
    "## Model-selection procedure", "",
    if (nrow(selection)) .gp3ml_markdown_table(selection) else "No governed model-selection procedure was supplied.", "",
    "## Target-aligned uncertainty", "",
    if (nrow(uncertainty)) .gp3ml_markdown_table(uncertainty) else "No target-aligned uncertainty object was supplied.",
    if (!is.null(card$uncertainty)) paste0("\nResampling unit: `", card$uncertainty$unit, "`.\n\n", card$uncertainty$limitations) else "", "",
    "## Calibration", "",
    if (inherits(card$calibration, "gp3ml_calibration_assessment")) .gp3ml_markdown_table(card$calibration$summary) else "No calibration assessment was supplied.", "",
    "## External validation and transportability", "",
    paste0("Status: **", card$external_validation_status, "**"),
    if (is.null(transportability)) "No independent external validation has been supplied." else transportability$reason, "",
    "## Limitations", "", paste0("- ", card$limitations), "",
    "## Prohibited uses", "", paste0("- ", card$prohibited_uses), "",
    "## Human oversight", "",
    "Predictions support scientific review only. Selection, interpretation, and any subsequent action remain subject to documented human review."
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

#' Create a release evidence manifest
#'
#' @param objects Named analysis objects to fingerprint.
#' @param files Named file paths to checksum.
#' @param version Intended future release version.
#' @param notes Optional release notes.
#'
#' @return A `gp3ml_release_evidence` object.
#' @export
create_gazepoint_release_evidence <- function(
    objects = list(),
    files = character(),
    version = "0.2.0",
    notes = character()) {
  if (is.null(names(objects)) && length(objects)) .gp3ml_stop("`objects` must be named.")
  if (length(files) && (is.null(names(files)) || any(!file.exists(files)))) {
    .gp3ml_stop("`files` must be a named vector of existing paths.")
  }
  structure(
    list(
      version = version,
      created_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      object_hashes = if (length(objects)) vapply(objects, .gp3ml_hash_object, character(1)) else character(),
      file_md5 = if (length(files)) tools::md5sum(files) else character(),
      file_paths = files,
      session = utils::capture.output(utils::sessionInfo()),
      notes = as.character(notes),
      prohibited_uses = gp3ml_prohibited_uses()
    ),
    class = "gp3ml_release_evidence"
  )
}

#' @rdname create_gazepoint_release_model_card
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_release_model_card
#' @export
print.gp3ml_release_model_card <- function(x, ...) {
  cat("<gp3ml_release_model_card>\n")
  cat("  Outcome: ", x$task$outcome, "\n", sep = "")
  cat("  Target: ", x$generalization_target, "\n", sep = "")
  cat("  Selection recorded: ", x$selection_procedure_recorded, "\n", sep = "")
  cat("  Uncertainty unit: ", x$uncertainty_unit, "\n", sep = "")
  cat("  External validation: ", x$external_validation_status, "\n", sep = "")
  invisible(x)
}

#' @rdname create_gazepoint_release_evidence
#' @param x An object returned by the corresponding gp3ml constructor, evaluator, summarizer, or validator.
#' @param ... Additional arguments passed to the print method.
#' @method print gp3ml_release_evidence
#' @export
print.gp3ml_release_evidence <- function(x, ...) {
  cat("<gp3ml_release_evidence> version=", x$version, "\n", sep = "")
  cat("  Object hashes: ", length(x$object_hashes), "\n", sep = "")
  cat("  File checksums: ", length(x$file_md5), "\n", sep = "")
  invisible(x)
}
