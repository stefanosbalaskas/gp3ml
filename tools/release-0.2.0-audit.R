#!/usr/bin/env Rscript

# Read-only release decision audit. This script does not commit, tag, push,
# publish, or submit anything.
repository <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(file.exists(file.path(repository, "DESCRIPTION")))

git <- function(args) {
  output <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (status != 0L) stop("git ", paste(args, collapse = " "), " failed:\n", paste(output, collapse = "\n"), call. = FALSE)
  output
}

branch <- trimws(git(c("branch", "--show-current")))
head <- trimws(git(c("rev-parse", "HEAD")))
status <- git(c("status", "--porcelain=v1", "--untracked-files=all"))
local_tags <- git(c("tag", "--list", "v0.2.0"))
remote_tags <- git(c("ls-remote", "--tags", "origin", "refs/tags/v0.2.0", "refs/tags/v0.2.0^{}"))
description <- read.dcf("DESCRIPTION")
news <- readLines("NEWS.md", warn = FALSE, encoding = "UTF-8")

cat("Branch:", branch, "\n")
cat("HEAD:", head, "\n")
cat("Version:", unname(description[1L, "Version"]), "\n")
cat("Working tree entries:", length(status), "\n")
cat("Local v0.2.0 tag entries:", length(local_tags), "\n")
cat("Remote v0.2.0 tag entries:", length(remote_tags), "\n")

stopifnot(
  identical(unname(description[1L, "Package"]), "gp3ml"),
  unname(description[1L, "Version"]) %in% c("0.2.0.9000", "0.2.0"),
  any(grepl("gp3ml 0.2.0", news, fixed = TRUE)),
  length(local_tags) == 0L,
  length(remote_tags) == 0L
)

required_files <- c(
  "R/roadmap-utils.R",
  "R/resample-evaluation.R",
  "R/model-tuning.R",
  "R/nested-resampling.R",
  "R/target-uncertainty.R",
  "R/external-validation-expansion.R",
  "R/synthetic-workflows.R",
  "R/roadmap-reporting.R",
  "tools/roadmap-smoke-test.R",
  "tools/validate-roadmap.R",
  "tests/testthat/test-roadmap-writers.R"
)
stopifnot(all(file.exists(required_files)))
stopifnot(length(list.files("vignettes", pattern = "\\.Rmd$")) == 9L)

cat(
  "RELEASE 0.2.0 READ-ONLY AUDIT PASSED.\n",
  "The code inventory is present and no v0.2.0 tag exists.\n",
  "Run full tests, pkgdown, source build, manual generation, and R CMD check\n",
  "before deciding whether 0.2.0 is release-ready.\n",
  "Nothing was modified, tagged, pushed, published, or submitted.\n",
  sep = ""
)
