# Regenerate package facts used in the manuscript.
args <- commandArgs(trailingOnly = TRUE)
repo_root <- if (length(args)) normalizePath(args[[1L]], winslash = "/", mustWork = TRUE) else normalizePath(".", winslash = "/", mustWork = TRUE)
paper_dir <- file.path(repo_root, "paper")
source(file.path(paper_dir, "R", "helpers.R"), local = TRUE)
if (!requireNamespace("gp3ml", quietly = TRUE)) stop("Install the current repository in a temporary library before running this audit.")
facts <- package_audit(repo_root)
print(facts[c("package", "version", "exports_from_namespace", "stable_exports", "experimental_exports", "stable_classes", "api_audit_status", "api_differences", "source_vignettes", "rd_topics", "optional_dependencies")])
print(facts$engines)
