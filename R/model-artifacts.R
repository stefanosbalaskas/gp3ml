.gp3ml_artifact_schema <- function(model, reference_data = NULL) {
  predictors <- model$predictors %||% character()
  if (is.null(reference_data)) {
    return(list(predictors=predictors, classes=NULL))
  }
  missing <- setdiff(predictors, names(reference_data))
  if (length(missing)) .gp3ml_ng_stop("Reference data are missing model predictors: %s.", paste(missing, collapse=", "))
  classes <- vapply(reference_data[predictors], function(x) paste(class(x), collapse="/"), character(1))
  list(predictors=predictors, classes=classes)
}

#' Create a portable governed model artifact
#'
#' @param model A fitted `gp3ml_model` or controlled model object.
#' @param preprocessor Optional preprocessing object.
#' @param feature_manifest Optional feature manifest.
#' @param task Optional task; defaults to `model$task`.
#' @param decision_rule Optional decision rule.
#' @param model_card Optional model card.
#' @param reference_data Optional deterministic prediction fixture.
#' @param bundle_model Whether to attempt `bundle::bundle()` when available.
#' @return A `gp3ml_model_artifact`.
#' @export
create_gazepoint_model_artifact <- function(
    model,
    preprocessor = model$preprocessor %||% NULL,
    feature_manifest = NULL,
    task = model$task %||% NULL,
    decision_rule = NULL,
    model_card = NULL,
    reference_data = NULL,
    bundle_model = TRUE) {
  if (is.null(model)) .gp3ml_ng_stop("`model` is required.")
  payload_model <- model
  bundled <- FALSE
  bundle_error <- NULL
  if (isTRUE(bundle_model) && requireNamespace("bundle", quietly=TRUE)) {
    attempt <- try(bundle::bundle(model), silent=TRUE)
    if (!inherits(attempt, "try-error")) {
      payload_model <- attempt
      bundled <- TRUE
    } else {
      bundle_error <- as.character(attempt)
    }
  }
  schema <- .gp3ml_artifact_schema(model, reference_data)
  metadata <- list(
    gp3ml_version = as.character(utils::packageVersion("gp3ml")),
    engine = model$engine %||% model$engine_name %||% NA_character_,
    engine_version = if (!is.null(model$engine) && is.character(model$engine))
      .gp3ml_ng_package_version(model$engine) else NA_character_,
    R_version = R.version.string,
    platform = R.version$platform,
    git_sha = .gp3ml_ng_git_sha("."),
    bundled = bundled,
    bundle_error = bundle_error
  )
  payload <- list(
    model = payload_model,
    preprocessor = preprocessor,
    feature_manifest = feature_manifest,
    task = task,
    decision_rule = decision_rule,
    model_card = model_card,
    predictor_schema = schema,
    reference_data = reference_data,
    metadata = metadata
  )
  hash <- .gp3ml_ng_hash_object(payload)
  structure(c(payload, list(artifact_hash=hash)), class="gp3ml_model_artifact")
}

#' Restore a model artifact
#' @param artifact A model artifact.
#' @return A restored artifact with an unbundled model where needed.
#' @export
restore_gazepoint_model_artifact <- function(artifact) {
  validation <- validate_gazepoint_model_artifact(artifact, verify_hash=TRUE)
  if (identical(validation$status, "fail")) .gp3ml_ng_stop("Artifact validation failed.")
  out <- artifact
  if (isTRUE(out$metadata$bundled)) {
    .gp3ml_ng_require("bundle", "The artifact contains a bundled model.")
    out$model <- bundle::unbundle(out$model)
    out$metadata$bundled <- FALSE
    out$metadata$restored_from_bundle <- TRUE
  }
  out
}

#' Validate a model artifact
#' @param artifact Artifact to validate.
#' @param verify_hash Whether to recompute the SHA-256 payload hash.
#' @return A validation object.
#' @export
validate_gazepoint_model_artifact <- function(artifact, verify_hash = TRUE) {
  checks <- data.frame(
    check=c("class","model","task","schema","metadata","hash"),
    status="pass", detail="", stringsAsFactors=FALSE
  )
  if (!inherits(artifact, "gp3ml_model_artifact")) {
    checks$status[] <- "fail"
  } else {
    if (is.null(artifact$model)) checks$status[checks$check=="model"] <- "fail"
    if (is.null(artifact$task)) checks$status[checks$check=="task"] <- "review"
    if (is.null(artifact$predictor_schema)) checks$status[checks$check=="schema"] <- "fail"
    if (is.null(artifact$metadata)) checks$status[checks$check=="metadata"] <- "fail"
    if (isTRUE(verify_hash)) {
      if (is.null(artifact$artifact_hash)) {
        checks$status[checks$check=="hash"] <- "fail"
      } else {
        payload <- unclass(artifact)
        payload$artifact_hash <- NULL
        actual <- .gp3ml_ng_hash_object(payload)
        if (!identical(actual, artifact$artifact_hash))
          checks$status[checks$check=="hash"] <- "fail"
      }
    }
  }
  structure(list(status=.gp3ml_ng_status(checks$status), checks=checks),
            class="gp3ml_model_artifact_validation")
}

#' Test model-artifact serialization and optional fresh-process prediction
#'
#' @param artifact Model artifact.
#' @param newdata Optional prediction fixture.
#' @param tolerance Numeric prediction tolerance.
#' @param fresh_process Whether to test in a fresh R process using `callr`.
#' @return A `gp3ml_model_portability_test`.
#' @export
test_gazepoint_model_portability <- function(
    artifact,
    newdata = artifact$reference_data,
    tolerance = 1e-8,
    fresh_process = FALSE) {
  validation <- validate_gazepoint_model_artifact(artifact, verify_hash=TRUE)
  if (identical(validation$status, "fail")) .gp3ml_ng_stop("Artifact is invalid before portability testing.")
  path <- tempfile(fileext=".rds")
  on.exit(unlink(path), add=TRUE)
  saveRDS(artifact, path, version=3)
  roundtrip <- readRDS(path)
  roundtrip_valid <- validate_gazepoint_model_artifact(roundtrip, verify_hash=TRUE)
  prediction_equal <- NA
  fresh_ok <- NA
  fresh_error <- NULL

  if (!is.null(newdata)) {
    restored <- restore_gazepoint_model_artifact(roundtrip)
    baseline <- try(stats::predict(restore_gazepoint_model_artifact(artifact)$model, newdata=newdata), silent=TRUE)
    after <- try(stats::predict(restored$model, newdata=newdata), silent=TRUE)
    if (!inherits(baseline, "try-error") && !inherits(after, "try-error")) {
      prediction_equal <- isTRUE(all.equal(as.numeric(baseline), as.numeric(after), tolerance=tolerance))
    }
  }

  if (isTRUE(fresh_process)) {
    .gp3ml_ng_require("callr")
    result <- try(
      callr::r(
        function(path) {
          suppressPackageStartupMessages(library(gp3ml))
          a <- readRDS(path)
          inherits(a, "gp3ml_model_artifact") && !is.null(a$model)
        },
        args=list(path=path)
      ),
      silent=TRUE
    )
    if (inherits(result, "try-error")) {
      fresh_ok <- FALSE
      fresh_error <- as.character(result)
    } else fresh_ok <- isTRUE(result)
  }

  statuses <- c(
    roundtrip = identical(roundtrip_valid$status, "pass"),
    prediction = if (is.na(prediction_equal)) TRUE else prediction_equal,
    fresh_process = if (is.na(fresh_ok)) TRUE else fresh_ok
  )
  structure(
    list(
      status=if (all(statuses)) "pass" else "fail",
      roundtrip_valid=roundtrip_valid$status,
      prediction_equal=prediction_equal,
      fresh_process_ok=fresh_ok,
      fresh_process_error=fresh_error,
      artifact_hash=artifact$artifact_hash
    ),
    class="gp3ml_model_portability_test"
  )
}

#' Plot model-artifact validation
#' @param x A `gp3ml_model_artifact_validation`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_model_artifact_validation
#' @export
plot.gp3ml_model_artifact_validation <- function(x, ...) {
  values <- c(pass=sum(x$checks$status=="pass"), review=sum(x$checks$status=="review"),
              fail=sum(x$checks$status=="fail"))
  graphics::barplot(values, ylab="Checks", main="Model artifact validation", ...)
  invisible(x)
}
