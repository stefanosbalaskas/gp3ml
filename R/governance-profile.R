.gp3ml_governance_domains <- function(framework) {
  base <- data.frame(
    control=c(
      "scientific purpose",
      "intended and prohibited use",
      "data and feature provenance",
      "generalization target",
      "leakage-resistant validation",
      "performance and calibration",
      "prediction-level uncertainty",
      "external validation and shift",
      "human oversight and decision rule",
      "reproducibility and artifact provenance"
    ),
    evidence_key=c(
      "task","task","feature_manifest","task","folds",
      "performance","conformal","transportability","decision_rule","research_artifact"
    ),
    stringsAsFactors=FALSE
  )
  base$framework_domain <- switch(
    framework,
    "gp3ml-native" = c("purpose","governance","provenance","generalization","validation",
                       "evaluation","uncertainty","transportability","oversight","reproducibility"),
    "NIST-AI-RMF-1.0" = c("GOVERN/MAP","GOVERN/MAP","MAP","MAP","MEASURE",
                          "MEASURE","MEASURE","MEASURE/MANAGE","GOVERN/MANAGE","GOVERN/MANAGE"),
    "ISO-23894-oriented" = rep("AI risk-management evidence", 10),
    "ISO-42001-oriented" = rep("AI management-system evidence", 10)
  )
  base
}

#' Create a governance-evidence profile
#'
#' @param evidence Named list of gp3ml evidence objects.
#' @param framework Governance crosswalk.
#' @return A `gp3ml_governance_profile`.
#' @export
create_gp3ml_governance_profile <- function(
    evidence,
    framework=c("gp3ml-native","NIST-AI-RMF-1.0","ISO-23894-oriented","ISO-42001-oriented")) {
  framework <- match.arg(framework)
  if (!is.list(evidence) || is.null(names(evidence))) .gp3ml_ng_stop("`evidence` must be a named list.")
  structure(
    list(
      framework=framework,
      evidence=evidence,
      controls=.gp3ml_governance_domains(framework),
      disclaimer=if (framework=="gp3ml-native")
        "gp3ml-native governance evidence profile."
      else
        "Documentation crosswalk only; this is not evidence of NIST endorsement, ISO conformity, certification, or legal compliance."
    ),
    class="gp3ml_governance_profile"
  )
}

#' Audit a governance-evidence profile
#' @param profile Governance profile.
#' @return A `gp3ml_governance_profile_audit`.
#' @export
audit_gp3ml_governance_profile <- function(profile) {
  if (!inherits(profile, "gp3ml_governance_profile")) .gp3ml_ng_stop("Invalid governance profile.")
  tab <- profile$controls
  tab$status <- vapply(tab$evidence_key, function(key) {
    value <- profile$evidence[[key]]
    if (is.null(value)) "review" else "pass"
  }, character(1))
  tab$evidence_class <- vapply(tab$evidence_key, function(key) {
    value <- profile$evidence[[key]]
    if (is.null(value)) "" else paste(class(value), collapse="/")
  }, character(1))
  structure(
    list(status=.gp3ml_ng_status(tab$status), framework=profile$framework,
         controls=tab, disclaimer=profile$disclaimer),
    class="gp3ml_governance_profile_audit"
  )
}

#' Write a governance profile audit
#' @param audit Governance profile audit.
#' @param path Markdown output path.
#' @return Output path, invisibly.
#' @export
write_gp3ml_governance_profile <- function(audit, path) {
  if (!inherits(audit, "gp3ml_governance_profile_audit")) .gp3ml_ng_stop("Invalid governance audit.")
  lines <- c(
    paste0("# gp3ml governance profile - ", audit$framework),
    "",
    audit$disclaimer,
    "",
    .gp3ml_ng_md_table(audit$controls)
  )
  dir.create(dirname(path), recursive=TRUE, showWarnings=FALSE)
  writeLines(lines, path, useBytes=TRUE)
  invisible(normalizePath(path, winslash="/", mustWork=TRUE))
}

#' Plot a governance profile audit
#' @param x Governance profile audit.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_governance_profile_audit
#' @export
plot.gp3ml_governance_profile_audit <- function(x, ...) {
  values <- c(pass=sum(x$controls$status=="pass"), review=sum(x$controls$status=="review"),
              fail=sum(x$controls$status=="fail"))
  graphics::barplot(values, ylab="Controls", main=paste("Governance evidence:", x$framework), ...)
  invisible(x)
}
