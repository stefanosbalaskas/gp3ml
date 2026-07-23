#!/usr/bin/env Rscript

required_packages <- c("pkgload", "devtools", "testthat", "pkgdown", "roxygen2")
missing <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install validation packages first: ", paste(missing, collapse = ", "), call. = FALSE)
}

repository <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(file.exists(file.path(repository, "DESCRIPTION")))
description <- read.dcf(file.path(repository, "DESCRIPTION"))
stopifnot(
  identical(unname(description[1L, "Package"]), "gp3ml"),
  identical(unname(description[1L, "Version"]), "0.2.0.9000")
)

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
test_files <- list.files("tests/testthat", pattern = "\\.R$", full.names = TRUE)
vignette_files <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)
stopifnot(
  length(vignette_files) == 9L,
  length(test_files) >= 10L,
  file.exists("tests/testthat/test-roadmap-writers.R")
)
invisible(lapply(c(r_files, test_files), function(path) parse(path, keep.source = TRUE)))
cat("PASS: all R and test files parse; nine vignettes are present.\n")

if ("gp3ml" %in% loadedNamespaces()) pkgload::unload("gp3ml")
devtools::document(quiet = FALSE)
pkgload::load_all(".", attach = FALSE, export_all = FALSE, quiet = TRUE)
source("tools/roadmap-smoke-test.R", local = new.env(parent = globalenv()))

testthat::test_local(".", reporter = "summary", stop_on_failure = TRUE)
cat("PASS: complete local test suite executed.\n")

site_dir <- tempfile("gp3ml-roadmap-site-")
pkgdown::build_site(pkg = ".", new_process = TRUE, dest_dir = site_dir, preview = FALSE)
html <- list.files(site_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
article_names <- tools::file_path_sans_ext(basename(vignette_files))
missing_articles <- article_names[!file.exists(file.path(site_dir, "articles", paste0(article_names, ".html")))]
stopifnot(length(html) > 0L, length(missing_articles) == 0L)
unlink(site_dir, recursive = TRUE, force = TRUE)
cat("PASS: pkgdown built all nine analytical-roadmap articles in a temporary site.\n")

check <- devtools::check(
  pkg = ".",
  args = "--as-cran",
  document = FALSE,
  manual = TRUE,
  cran = TRUE,
  error_on = "never",
  quiet = FALSE
)
stopifnot(
  length(check$errors) == 0L,
  length(check$warnings) == 0L,
  length(check$notes) == 0L
)
cat("ROADMAP VALIDATION PASSED: 0 errors, 0 warnings, 0 notes.\n")
