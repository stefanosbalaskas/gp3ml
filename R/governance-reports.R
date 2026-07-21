.gp3ml_markdown_table <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return("_No rows._")
  values <- lapply(x, function(column) { column <- as.character(column); column[is.na(column)] <- ""; gsub("\\|", "\\\\|", column) })
  x <- as.data.frame(values, stringsAsFactors = FALSE)
  c(
    paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
    apply(x, 1L, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  )
}

#' Create a governance-focused model card
#'
#' @param model A fitted `gp3ml_model` object.
#' @param intended_use Explicit description of the intended research use.
#' @param evaluation Optional performance-evaluation object.
#' @param calibration Optional calibration-assessment object.
#' @param feature_manifest Optional feature-provenance manifest.
#' @param external_validation Optional external-validation result.
#' @param limitations Character vector describing model limitations.
#' @param ethical_review Optional ethical-review information.
#'
#' @examples
#' training_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' training_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = training_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' model <- train_gazepoint_classifier(
#'   data = training_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' card <- create_gazepoint_model_card(
#'   model = model,
#'   intended_use = paste(
#'     "Support manual review of predefined",
#'     "recording-quality status"
#'   ),
#'   limitations = "Synthetic example for documentation."
#' )
#' card
#' @return A `gp3ml_model_card` object containing task, model, governance, evaluation, calibration, provenance, external-validation, and limitation metadata.
#' @export
create_gazepoint_model_card <- function(
    model,
    intended_use,
    evaluation = NULL,
    calibration = NULL,
    feature_manifest = NULL,
    external_validation = NULL,
    limitations = character(),
    ethical_review = NULL) {
  if (!inherits(model, "gp3ml_model")) .gp3ml_stop("`model` must be a fitted gp3ml model.")
  assert_gp3ml_use_case(model$task)
  structure(
    list(
      title = paste("Model card:", model$task$outcome),
      created_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      intended_use = intended_use,
      prohibited_uses = gp3ml_prohibited_uses(),
      task = model$task,
      engine = model$engine,
      predictors = model$predictors,
      training_n = model$training_n,
      training_hash = model$training_hash,
      evaluation = evaluation,
      calibration = calibration,
      feature_manifest = feature_manifest,
      external_validation = external_validation,
      limitations = limitations,
      ethical_review = ethical_review
    ),
    class = "gp3ml_model_card"
  )
}

.gp3ml_model_card_markdown <- function(card) {
  metrics <- if (inherits(card$evaluation, "gp3ml_resample_evaluation")) card$evaluation$metrics else if (inherits(card$evaluation, "gp3ml_metric_uncertainty")) card$evaluation$intervals else if (is.data.frame(card$evaluation)) card$evaluation else data.frame()
  calibration <- if (inherits(card$calibration, "gp3ml_calibration_assessment")) card$calibration$summary else data.frame()
  c(
    paste0("# ", card$title), "",
    paste0("Generated: ", card$created_at), "",
    "## Intended use", "", card$intended_use, "",
    "## Task contract", "",
    paste0("- Outcome: `", card$task$outcome, "`"),
    paste0("- Type: `", card$task$task_type, "`"),
    paste0("- Unit: `", card$task$unit_id, "`"),
    paste0("- Generalization target: `", card$task$generalization_target, "`"),
    paste0("- Scientific purpose: ", card$task$purpose), "",
    "## Model", "", paste0("- Engine: `", card$engine, "`"), paste0("- Training rows: ", card$training_n), paste0("- Training hash: `", card$training_hash, "`"), paste0("- Predictors: ", paste(sprintf("`%s`", card$predictors), collapse = ", ")), "",
    "## Performance", "", .gp3ml_markdown_table(metrics), "",
    "## Calibration", "", .gp3ml_markdown_table(calibration), "",
    "## Prohibited uses", "", paste0("- ", card$prohibited_uses), "",
    "## Limitations", "", if (length(card$limitations)) paste0("- ", card$limitations) else "- No limitations were supplied; this must be completed before deployment.", "",
    "## External validation", "", if (is.null(card$external_validation)) "No independent external validation has been supplied." else "An external-validation report is attached to the card.", "",
    "## Human oversight", "", "Predictions must support research review rather than autonomous consequential decisions."
  )
}

.gp3ml_json_ready <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "POSIXt")) {
    return(format(x, tz = "UTC", usetz = TRUE))
  }
  if (inherits(x, "Date")) return(format(x))
  if (is.factor(x)) return(as.character(x))
  if (is.data.frame(x)) {
    output <- lapply(x, .gp3ml_json_ready)
    names(output) <- names(x)
    output <- as.data.frame(
      output,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      optional = TRUE
    )
    row.names(output) <- NULL
    return(output)
  }
  if (is.matrix(x) || is.array(x)) return(x)
  if (is.function(x)) return("<function>")
  if (is.environment(x)) return("<environment>")
  if (is.language(x)) return(paste(deparse(x), collapse = " "))
  if (is.list(x)) {
    output <- lapply(x, .gp3ml_json_ready)
    names(output) <- names(x)
    return(output)
  }
  if (is.atomic(x)) {
    if (is.object(x)) return(unclass(x))
    return(x)
  }
  as.character(x)
}

#' Write a model card
#'
#' @param card A `gp3ml_model_card` object.
#' @param path Destination file path.
#' @param format Output format: Markdown or JSON.
#' @param overwrite Whether an existing file may be replaced.
#'
#' @examples
#' training_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' training_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = training_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' model <- train_gazepoint_classifier(
#'   data = training_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' card <- create_gazepoint_model_card(
#'   model = model,
#'   intended_use = paste(
#'     "Support manual review of predefined",
#'     "recording-quality status"
#'   ),
#'   limitations = "Synthetic example for documentation."
#' )
#' output <- tempfile(fileext = ".md")
#' write_gazepoint_model_card(
#'   card = card,
#'   path = output,
#'   format = "markdown"
#' )
#' file.exists(output)
#' unlink(output)
#' @return The destination path, returned invisibly after the model card is written.
#' @export
write_gazepoint_model_card <- function(card, path, format = c("markdown", "json"), overwrite = FALSE) {
  format <- match.arg(format)
  if (!inherits(card, "gp3ml_model_card")) {
    .gp3ml_stop("`card` must be created by `create_gazepoint_model_card()`.")
  }
  if (file.exists(path) && !overwrite) .gp3ml_stop("File exists: %s.", path)
  if (format == "markdown") {
    writeLines(.gp3ml_model_card_markdown(card), path, useBytes = TRUE)
  } else {
    if (!requireNamespace("jsonlite", quietly = TRUE)) .gp3ml_stop("Install `jsonlite` for JSON output.")
    payload <- .gp3ml_json_ready(card)
    jsonlite::write_json(
      payload,
      path,
      pretty = TRUE,
      auto_unbox = TRUE,
      null = "null",
      na = "null"
    )
  }
  invisible(path)
}

.gp3ml_shift_diagnostics <- function(model, external_data) {
  .gp3ml_bind_rows(lapply(model$predictors, function(name) {
    train <- model$predictor_summary[[name]]; x <- external_data[[name]]
    if (train$type == "numeric") {
      data.frame(feature = name, type = "numeric", standardized_mean_difference = if (!is.finite(train$sd) || train$sd == 0) NA_real_ else (mean(x, na.rm = TRUE) - train$mean) / train$sd, novel_levels = NA_character_, external_missing = sum(is.na(x)))
    } else {
      novel <- setdiff(unique(as.character(x[!is.na(x)])), train$levels)
      data.frame(feature = name, type = "categorical", standardized_mean_difference = NA_real_, novel_levels = paste(novel, collapse = ", "), external_missing = sum(is.na(x)))
    }
  }))
}

#' Evaluate an independent external-validation dataset
#'
#' @param model A fitted `gp3ml_model` object.
#' @param external_data Independent external-validation data.
#' @param label Label identifying the validation dataset.
#' @param threshold Classification probability threshold.
#' @param bootstrap Number of calibration bootstrap replicates.
#' @param seed Deterministic random seed.
#'
#' @examples
#' training_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' training_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = training_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' model <- train_gazepoint_classifier(
#'   data = training_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' external_data <- training_data
#' external_data$participant_id <- rep(
#'   sprintf("E%02d", 1:12),
#'   each = 2
#' )
#' external_data$trial_id <- sprintf("ET%02d", 1:24)
#' external_data$fixation_duration <-
#'   external_data$fixation_duration + 4
#' external_data$pupil_change <- cos(seq_len(24) / 4)
#' validation <- evaluate_external_validation(
#'   model = model,
#'   external_data = external_data,
#'   label = "synthetic_external",
#'   bootstrap = 10L,
#'   seed = 101L
#' )
#' validation
#' @return A `gp3ml_external_validation` object containing external predictions, performance metrics, calibration results where applicable, predictor-shift diagnostics, a dataset fingerprint, and task metadata.
#' @export
evaluate_external_validation <- function(model, external_data, label = "external", threshold = model$threshold, bootstrap = 200L, seed = 1L) {
  .gp3ml_assert_data(external_data)
  assert_gp3ml_use_case(model$task, external_data)
  if (model$task$task_type == "classification") {
    probability <- stats::predict(model, external_data, type = "probability")
    prediction <- stats::predict(model, external_data, type = "class")
    metrics <- gazepoint_classification_metrics(external_data[[model$task$outcome]], probability, prediction, model$task$positive, threshold)
    calibration <- assess_gazepoint_calibration(external_data[[model$task$outcome]], probability, model$task$positive, bootstrap = bootstrap, seed = seed)
    predictions <- data.frame(truth = as.character(external_data[[model$task$outcome]]), prediction = as.character(prediction), probability = probability)
  } else {
    prediction <- stats::predict(model, external_data)
    metrics <- gazepoint_regression_metrics(external_data[[model$task$outcome]], prediction)
    calibration <- NULL
    predictions <- data.frame(truth = external_data[[model$task$outcome]], prediction = prediction)
  }
  structure(list(label = label, created_at = format(Sys.time(), tz = "UTC", usetz = TRUE), metrics = metrics, calibration = calibration, shift = .gp3ml_shift_diagnostics(model, external_data), predictions = predictions, external_hash = .gp3ml_hash_object(external_data[c(model$task$outcome, model$predictors)]), task = model$task, model_engine = model$engine), class = "gp3ml_external_validation")
}

#' Create an external-validation report object
#'
#' @param validation A `gp3ml_external_validation` object.
#' @param development_metrics Optional development-sample metrics.
#' @param limitations Character vector describing report limitations.
#'
#' @examples
#' training_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' training_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = training_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' model <- train_gazepoint_classifier(
#'   data = training_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' external_data <- training_data
#' external_data$participant_id <- rep(
#'   sprintf("E%02d", 1:12),
#'   each = 2
#' )
#' external_data$trial_id <- sprintf("ET%02d", 1:24)
#' external_data$fixation_duration <-
#'   external_data$fixation_duration + 4
#' external_data$pupil_change <- cos(seq_len(24) / 4)
#' validation <- evaluate_external_validation(
#'   model = model,
#'   external_data = external_data,
#'   label = "synthetic_external",
#'   bootstrap = 10L,
#'   seed = 101L
#' )
#' report <- create_external_validation_report(
#'   validation = validation,
#'   limitations = "Synthetic external-validation example."
#' )
#' report
#' @return A `gp3ml_external_validation_report` object containing the validation result, optional development metrics, limitations, and prohibited-use information.
#' @export
create_external_validation_report <- function(validation, development_metrics = NULL, limitations = character()) {
  if (!inherits(validation, "gp3ml_external_validation")) .gp3ml_stop("Supply `evaluate_external_validation()` output.")
  structure(list(validation = validation, development_metrics = development_metrics, limitations = limitations, prohibited_uses = gp3ml_prohibited_uses()), class = "gp3ml_external_validation_report")
}

#' Write an external-validation report
#'
#' @param report A `gp3ml_external_validation_report` object.
#' @param path Destination Markdown file path.
#' @param overwrite Whether an existing file may be replaced.
#'
#' @examples
#' training_data <- data.frame(
#'   participant_id = rep(sprintf("P%02d", 1:12), each = 2),
#'   trial_id = sprintf("T%02d", 1:24),
#'   stimulus_id = rep(c("S01", "S02"), 12),
#'   fixation_duration = 180 + seq_len(24),
#'   pupil_change = sin(seq_len(24) / 3),
#'   stringsAsFactors = FALSE
#' )
#' training_data$quality_status <- factor(
#'   c(
#'     "pass", "review", "pass", "review", "review", "pass",
#'     "review", "pass", "pass", "review", "review", "pass",
#'     "review", "pass", "review", "pass", "pass", "review",
#'     "pass", "review", "review", "pass", "pass", "review"
#'   ),
#'   levels = c("pass", "review")
#' )
#' task <- declare_gazepoint_task(
#'   data = training_data,
#'   outcome = "quality_status",
#'   purpose = "Predict predefined recording-quality review status",
#'   task_type = "classification",
#'   unit_id = "trial_id",
#'   participant_id = "participant_id",
#'   stimulus_id = "stimulus_id",
#'   generalization_target = "new_participants",
#'   positive = "review"
#' )
#' model <- train_gazepoint_classifier(
#'   data = training_data,
#'   task = task,
#'   predictors = c("fixation_duration", "pupil_change"),
#'   engine = "glm",
#'   seed = 101L
#' )
#' external_data <- training_data
#' external_data$participant_id <- rep(
#'   sprintf("E%02d", 1:12),
#'   each = 2
#' )
#' external_data$trial_id <- sprintf("ET%02d", 1:24)
#' external_data$fixation_duration <-
#'   external_data$fixation_duration + 4
#' external_data$pupil_change <- cos(seq_len(24) / 4)
#' validation <- evaluate_external_validation(
#'   model = model,
#'   external_data = external_data,
#'   label = "synthetic_external",
#'   bootstrap = 10L,
#'   seed = 101L
#' )
#' report <- create_external_validation_report(validation)
#' output <- tempfile(fileext = ".md")
#' write_external_validation_report(report, output)
#' file.exists(output)
#' unlink(output)
#' @return The destination path, returned invisibly after the Markdown report is written.
#' @export
write_external_validation_report <- function(report, path, overwrite = FALSE) {
  if (file.exists(path) && !overwrite) .gp3ml_stop("File exists: %s.", path)
  v <- report$validation
  lines <- c(
    paste0("# External validation: ", v$label), "",
    paste0("Generated: ", v$created_at), "",
    "## External performance", "", .gp3ml_markdown_table(v$metrics), "",
    "## Development performance", "", if (is.null(report$development_metrics)) "Not supplied." else .gp3ml_markdown_table(report$development_metrics), "",
    "## Calibration", "", if (is.null(v$calibration)) "Not applicable." else .gp3ml_markdown_table(v$calibration$summary), "",
    "## Predictor shift", "", .gp3ml_markdown_table(v$shift), "",
    "## Dataset fingerprint", "", paste0("`", v$external_hash, "`"), "",
    "## Limitations", "", if (length(report$limitations)) paste0("- ", report$limitations) else "- External representativeness and transportability require substantive review.", "",
    "## Prohibited uses", "", paste0("- ", report$prohibited_uses)
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

#' Create a reproducibility report
#'
#' @param objects Named objects to fingerprint.
#' @param data Optional data frame to fingerprint.
#' @param seeds Named list of deterministic seeds.
#' @param notes Optional reproducibility notes.
#' @param project_path Project directory recorded in the report.
#'
#' @examples
#' example_data <- data.frame(
#'   trial_id = sprintf("T%02d", 1:6),
#'   fixation_duration = c(190, 205, 198, 214, 202, 220),
#'   stringsAsFactors = FALSE
#' )
#' report <- create_gazepoint_reproducibility_report(
#'   objects = list(
#'     fixation_values = example_data$fixation_duration
#'   ),
#'   data = example_data,
#'   seeds = list(example = 101L),
#'   notes = "Synthetic documentation example.",
#'   project_path = tempdir()
#' )
#' report
#' @return A `gp3ml_reproducibility_report` object containing runtime information, object and data fingerprints, seeds, Git metadata, notes, and prohibited uses.
#' @export
create_gazepoint_reproducibility_report <- function(objects = list(), data = NULL, seeds = list(), notes = character(), project_path = getwd()) {
  object_hashes <- if (length(objects)) vapply(objects, .gp3ml_hash_object, character(1)) else character()
  data_hash <- if (is.null(data)) NA_character_ else .gp3ml_hash_object(data)
  git <- list(commit = NA_character_, branch = NA_character_, clean = NA)
  if (dir.exists(file.path(project_path, ".git"))) {
    git$commit <- tryCatch(system2("git", c("-C", shQuote(project_path), "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE)[[1L]], error = function(e) NA_character_)
    git$branch <- tryCatch(system2("git", c("-C", shQuote(project_path), "branch", "--show-current"), stdout = TRUE, stderr = FALSE)[[1L]], error = function(e) NA_character_)
    status <- tryCatch(system2("git", c("-C", shQuote(project_path), "status", "--porcelain"), stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
    git$clean <- length(status) == 0L
  }
  structure(list(created_at = format(Sys.time(), tz = "UTC", usetz = TRUE), r_version = R.version.string, platform = R.version$platform, session = utils::capture.output(utils::sessionInfo()), object_hashes = object_hashes, data_hash = data_hash, seeds = seeds, git = git, notes = notes, prohibited_uses = gp3ml_prohibited_uses()), class = "gp3ml_reproducibility_report")
}

#' Write a reproducibility report
#'
#' @param report A `gp3ml_reproducibility_report` object.
#' @param path Destination Markdown file path.
#' @param overwrite Whether an existing file may be replaced.
#'
#' @examples
#' example_data <- data.frame(
#'   trial_id = sprintf("T%02d", 1:6),
#'   fixation_duration = c(190, 205, 198, 214, 202, 220),
#'   stringsAsFactors = FALSE
#' )
#' report <- create_gazepoint_reproducibility_report(
#'   objects = list(
#'     fixation_values = example_data$fixation_duration
#'   ),
#'   data = example_data,
#'   seeds = list(example = 101L),
#'   notes = "Synthetic documentation example.",
#'   project_path = tempdir()
#' )
#' output <- tempfile(fileext = ".md")
#' write_gazepoint_reproducibility_report(report, output)
#' file.exists(output)
#' unlink(output)
#' @return The destination path, returned invisibly after the reproducibility report is written.
#' @export
write_gazepoint_reproducibility_report <- function(report, path, overwrite = FALSE) {
  if (file.exists(path) && !overwrite) .gp3ml_stop("File exists: %s.", path)
  lines <- c(
    "# gp3ml reproducibility report", "", paste0("Generated: ", report$created_at), "",
    "## Runtime", "", paste0("- R: ", report$r_version), paste0("- Platform: ", report$platform), "",
    "## Git", "", paste0("- Branch: `", report$git$branch, "`"), paste0("- Commit: `", report$git$commit, "`"), paste0("- Clean: ", report$git$clean), "",
    "## Fingerprints", "", paste0("- Data: `", report$data_hash, "`"), if (length(report$object_hashes)) paste0("- ", names(report$object_hashes), ": `", report$object_hashes, "`") else "- No objects supplied.", "",
    "## Seeds", "", if (length(report$seeds)) paste0("- ", names(report$seeds), ": ", unlist(report$seeds)) else "- No seeds supplied.", "",
    "## Notes", "", if (length(report$notes)) paste0("- ", report$notes) else "- None.", "",
    "## Session information", "", "```", report$session, "```", "",
    "## Prohibited uses", "", paste0("- ", report$prohibited_uses)
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

#' @method print gp3ml_model_card
#' @export
print.gp3ml_model_card <- function(x, ...) { cat("<gp3ml_model_card> ", x$title, "\n", sep = ""); invisible(x) }
#' @method print gp3ml_external_validation
#' @export
print.gp3ml_external_validation <- function(x, ...) { cat("<gp3ml_external_validation> ", x$label, "\n", sep = ""); print(x$metrics, row.names = FALSE); invisible(x) }
#' @method print gp3ml_reproducibility_report
#' @export
print.gp3ml_reproducibility_report <- function(x, ...) { cat("<gp3ml_reproducibility_report> ", x$created_at, "\n", sep = ""); invisible(x) }
