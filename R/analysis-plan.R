#' Declare a frozen-analysis-plan contract
#'
#' @param research_question Research question.
#' @param scientific_purpose Explicit scientific purpose.
#' @param outcome Outcome name.
#' @param outcome_definition Operational definition of the observed outcome.
#' @param predictors Predeclared predictors.
#' @param generalization_target Intended generalization target.
#' @param grouping_variables Grouping columns.
#' @param eligible_population Eligibility statement.
#' @param exclusion_rules Character vector of predeclared exclusions.
#' @param preprocessing_plan Preprocessing plan.
#' @param candidate_models Candidate model specifications or names.
#' @param primary_metric Primary metric.
#' @param secondary_metrics Secondary metrics.
#' @param calibration_metric Calibration metric.
#' @param uncertainty_method Uncertainty method.
#' @param threshold_policy Threshold/decision policy.
#' @param external_validation_required Whether independent validation is required.
#' @param seed_strategy Deterministic seed strategy.
#' @param prohibited_interpretations Character vector of prohibited interpretations.
#' @return A mutable `gp3ml_analysis_plan` until locked.
#' @export
declare_gazepoint_analysis_plan <- function(
    research_question,
    scientific_purpose,
    outcome,
    outcome_definition,
    predictors,
    generalization_target,
    grouping_variables = character(),
    eligible_population,
    exclusion_rules = character(),
    preprocessing_plan,
    candidate_models,
    primary_metric,
    secondary_metrics = character(),
    calibration_metric = NULL,
    uncertainty_method,
    threshold_policy = NULL,
    external_validation_required = FALSE,
    seed_strategy,
    prohibited_interpretations = gp3ml_prohibited_uses()) {
  structure(
    list(
      research_question = research_question,
      scientific_purpose = scientific_purpose,
      outcome = outcome,
      outcome_definition = outcome_definition,
      predictors = unique(as.character(predictors)),
      generalization_target = generalization_target,
      grouping_variables = unique(as.character(grouping_variables)),
      eligible_population = eligible_population,
      exclusion_rules = as.character(exclusion_rules),
      preprocessing_plan = preprocessing_plan,
      candidate_models = candidate_models,
      primary_metric = primary_metric,
      secondary_metrics = unique(as.character(secondary_metrics)),
      calibration_metric = calibration_metric,
      uncertainty_method = uncertainty_method,
      threshold_policy = threshold_policy,
      external_validation_required = isTRUE(external_validation_required),
      seed_strategy = seed_strategy,
      prohibited_interpretations = unique(as.character(prohibited_interpretations)),
      locked = FALSE,
      plan_id = NULL,
      plan_hash = NULL,
      locked_at = NULL
    ),
    class = "gp3ml_analysis_plan"
  )
}

#' Validate an analysis plan
#' @param plan A `gp3ml_analysis_plan`.
#' @return A validation object.
#' @export
validate_gazepoint_analysis_plan <- function(plan) {
  required <- c("research_question","scientific_purpose","outcome","outcome_definition",
                "predictors","generalization_target","eligible_population","preprocessing_plan",
                "candidate_models","primary_metric","uncertainty_method","seed_strategy",
                "prohibited_interpretations")
  checks <- data.frame(check=required, status="pass", detail="", stringsAsFactors=FALSE)
  if (!inherits(plan, "gp3ml_analysis_plan")) {
    checks$status[] <- "fail"
  } else {
    for (nm in required) {
      value <- plan[[nm]]
      empty <- is.null(value) || length(value) == 0L ||
        (is.character(value) && !any(nzchar(trimws(value))))
      if (empty) checks$status[checks$check == nm] <- "fail"
    }
    if (length(plan$predictors) != length(unique(plan$predictors)))
      checks$status[checks$check == "predictors"] <- "review"
    if (plan$outcome %in% plan$predictors)
      checks$status[checks$check == "predictors"] <- "fail"
  }
  structure(list(status=.gp3ml_ng_status(checks$status), checks=checks),
            class="gp3ml_analysis_plan_validation")
}

#' Lock an analysis plan using SHA-256
#' @param plan A valid unlocked plan.
#' @param plan_id Optional stable identifier.
#' @param locked_at Optional lock time.
#' @return A locked `gp3ml_analysis_plan`.
#' @export
lock_gazepoint_analysis_plan <- function(plan, plan_id = NULL, locked_at = Sys.time()) {
  validation <- validate_gazepoint_analysis_plan(plan)
  if (!identical(validation$status, "pass")) .gp3ml_ng_stop("Analysis plan must pass validation before locking.")
  if (isTRUE(plan$locked)) .gp3ml_ng_stop("Analysis plan is already locked.")
  base <- plan
  base$locked <- NULL
  base$plan_id <- NULL
  base$plan_hash <- NULL
  base$locked_at <- NULL
  hash <- .gp3ml_ng_hash_object(base)
  if (is.null(plan_id)) plan_id <- paste0("gp3ml-plan-", substr(hash, 1L, 12L))
  plan$locked <- TRUE
  plan$plan_id <- plan_id
  plan$plan_hash <- hash
  plan$locked_at <- format(as.POSIXct(locked_at, tz="UTC"), tz="UTC", usetz=TRUE)
  plan
}

#' Audit deviations from a locked analysis plan
#' @param plan A locked analysis plan.
#' @param actual Named list describing the analysis actually performed.
#' @param fields Fields to compare.
#' @return A `gp3ml_plan_deviation_audit`.
#' @export
audit_gazepoint_plan_deviations <- function(
    plan,
    actual,
    fields = c("outcome","predictors","generalization_target","primary_metric",
               "secondary_metrics","calibration_metric","uncertainty_method",
               "threshold_policy","candidate_models","preprocessing_plan")) {
  if (!inherits(plan, "gp3ml_analysis_plan") || !isTRUE(plan$locked))
    .gp3ml_ng_stop("A locked analysis plan is required.")
  if (!is.list(actual) || is.null(names(actual))) .gp3ml_ng_stop("`actual` must be a named list.")
  rows <- lapply(fields, function(nm) {
    planned <- plan[[nm]]
    observed <- actual[[nm]]
    same <- identical(planned, observed)
    data.frame(
      field=nm,
      status=if (same) "pass" else "deviation",
      planned=paste(utils::capture.output(utils::str(planned, give.attr=FALSE)), collapse=" "),
      actual=paste(utils::capture.output(utils::str(observed, give.attr=FALSE)), collapse=" "),
      stringsAsFactors=FALSE
    )
  })
  tab <- do.call(rbind, rows)
  structure(
    list(status=if (any(tab$status=="deviation")) "review" else "pass",
         plan_id=plan$plan_id, plan_hash=plan$plan_hash, deviations=tab),
    class="gp3ml_plan_deviation_audit"
  )
}

#' Write an analysis plan
#' @param plan Analysis plan.
#' @param path Output path.
#' @param format `"rds"`, `"json"`, or `"md"`.
#' @return Normalized output path, invisibly.
#' @export
write_gazepoint_analysis_plan <- function(plan, path, format = c("rds","json","md")) {
  format <- match.arg(format)
  validation <- validate_gazepoint_analysis_plan(plan)
  if (identical(validation$status, "fail")) .gp3ml_ng_stop("Cannot write an invalid analysis plan.")
  dir.create(dirname(path), recursive=TRUE, showWarnings=FALSE)
  if (format == "rds") {
    saveRDS(plan, path, version=3)
  } else if (format == "json") {
    .gp3ml_ng_require("jsonlite")
    jsonlite::write_json(unclass(plan), path, pretty=TRUE, auto_unbox=TRUE, null="null")
  } else {
    lines <- c(
      "# gp3ml analysis plan",
      "",
      paste0("- Plan ID: ", plan$plan_id %||% "<unlocked>"),
      paste0("- SHA-256: ", plan$plan_hash %||% "<unlocked>"),
      paste0("- Research question: ", plan$research_question),
      paste0("- Scientific purpose: ", plan$scientific_purpose),
      paste0("- Outcome: ", plan$outcome),
      paste0("- Generalization target: ", plan$generalization_target),
      paste0("- Primary metric: ", plan$primary_metric),
      paste0("- Predictors: ", paste(plan$predictors, collapse=", ")),
      paste0("- External validation required: ", plan$external_validation_required),
      "",
      "## Prohibited interpretations",
      paste0("- ", plan$prohibited_interpretations)
    )
    writeLines(lines, path, useBytes=TRUE)
  }
  invisible(normalizePath(path, winslash="/", mustWork=TRUE))
}

#' Plot analysis-plan deviations
#' @param x A `gp3ml_plan_deviation_audit`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_plan_deviation_audit
#' @export
plot.gp3ml_plan_deviation_audit <- function(x, ...) {
  counts <- table(factor(x$deviations$status, levels=c("pass","deviation")))
  graphics::barplot(counts, ylab="Fields", main="Analysis-plan deviation audit", ...)
  invisible(x)
}
