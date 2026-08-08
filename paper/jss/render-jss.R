#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x) || !nzchar(x)) y else x
}

script_path <- function() {
  x <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(x)) {
    return(sub("^--file=", "", x[[1L]]))
  }
  "paper/jss/render-jss.R"
}

main <- function() {
  jss_dir <- normalizePath(
    dirname(script_path()),
    winslash = "/",
    mustWork = TRUE
  )
  repo_root <- normalizePath(
    file.path(jss_dir, "..", ".."),
    winslash = "/",
    mustWork = TRUE
  )

  desc <- read.dcf(file.path(repo_root, "DESCRIPTION"))
  stopifnot(
    identical(unname(desc[1L, "Package"]), "gp3ml"),
    identical(unname(desc[1L, "Version"]), "0.3.0")
  )

  git <- Sys.which("git")
  if (nzchar(git)) {
    branch <- system2(
      git,
      c("-C", repo_root, "branch", "--show-current"),
      stdout = TRUE
    )
    stopifnot(identical(branch, "paper/jss-manuscript"))
  }

  required <- c(
    "article.tex", "refs.bib", "jss.cls", "jss.bst", "jsslogo.jpg",
    "code.R", "R/helpers.R", "R/case-study.R"
  )
  stopifnot(all(file.exists(file.path(jss_dir, required))))

  old_wd <- setwd(jss_dir)
  on.exit(setwd(old_wd), add = TRUE)

  tmp_lib <- tempfile("gp3ml-jss-lib-")
  dir.create(tmp_lib, recursive = TRUE, showWarnings = FALSE)

  r_exec <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
  install_status <- system2(
    r_exec,
    c(
      "CMD", "INSTALL",
      "--no-multiarch",
      "--with-keep.source",
      paste0("--library=", shQuote(tmp_lib)),
      shQuote(repo_root)
    )
  )
  stopifnot(identical(install_status, 0L))

  old_lib <- .libPaths()
  on.exit(.libPaths(old_lib), add = TRUE)
  .libPaths(c(tmp_lib, old_lib))

  stopifnot(
    requireNamespace("gp3ml", quietly = TRUE),
    as.character(utils::packageVersion("gp3ml")) == "0.3.0",
    requireNamespace("knitr", quietly = TRUE),
    requireNamespace("tinytex", quietly = TRUE),
    requireNamespace("pdftools", quietly = TRUE)
  )

  Sys.setenv(GP3ML_JSS_DIR = jss_dir)
  on.exit(Sys.unsetenv("GP3ML_JSS_DIR"), add = TRUE)

  # Replication errors must abort validation rather than be rendered as output.
  knitr::opts_chunk$set(
    error = FALSE
  )

  spin_out <- knitr::spin(
    "code.R",
    knit = TRUE,
    report = TRUE,
    format = "Rmd",
    envir = new.env(parent = globalenv())
  )
  message("knitr::spin output: ", spin_out)

  spin_intermediates <- c("code.Rmd", "code.md")
  unlink(
    spin_intermediates,
    force = TRUE
  )
  stopifnot(
    !any(file.exists(spin_intermediates))
  )

  html_candidates <- c("code.html", "code.htm")
  stopifnot(any(file.exists(html_candidates)))

  html_path <- html_candidates[file.exists(html_candidates)][1L]
  html_lines <- readLines(
    html_path,
    warn = FALSE,
    encoding = "UTF-8"
  )
  html_lines <- sub(
    "[ \\t]+$",
    "",
    html_lines,
    perl = TRUE
  )
  writeLines(
    html_lines,
    html_path,
    useBytes = TRUE
  )
  stopifnot(
    !any(grepl("[ \\t]+$", html_lines, perl = TRUE))
  )


  decision_policy_check <- utils::read.csv(
    file.path("output", "decision-policy-summary.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  stopifnot(
    nrow(decision_policy_check) == 1L,
    identical(decision_policy_check$rule_validation[[1L]], "pass"),
    abs(decision_policy_check$threshold[[1L]] - 0.20) < 1e-12,
    abs(decision_policy_check$abstention_lower[[1L]] - 0.15) < 1e-12,
    abs(decision_policy_check$abstention_upper[[1L]] - 0.25) < 1e-12,
    decision_policy_check$held_out_rows[[1L]] == 240L,
    abs(decision_policy_check$coverage[[1L]] - 0.6208333333333333) < 1e-12,
    abs(decision_policy_check$abstention_rate[[1L]] - 0.3791666666666667) < 1e-12,
    abs(decision_policy_check$covered_error_rate[[1L]] - 0.2214765100671141) < 1e-12,
    identical(decision_policy_check$audit_status[[1L]], "pass")
  )

  article_source <- paste(
    readLines("article.tex", warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  stopifnot(
    grepl("0.15--0.25", article_source, fixed = TRUE),
    grepl("coverage is 0.621", article_source, fixed = TRUE),
    grepl("abstention rate is 0.379", article_source, fixed = TRUE),
    grepl("covered cases is 0.221", article_source, fixed = TRUE),
    !grepl("coverage is 1.000, abstention is 0", article_source, fixed = TRUE),
    !grepl("0.2625", article_source, fixed = TRUE)
  )
  tinytex::latexmk(
    "article.tex",
    engine = "pdflatex",
    clean = FALSE
  )

  stopifnot(
    file.exists("article.pdf"),
    file.info("article.pdf")$size > 0L
  )

  latex_log <- readLines(
    "article.log",
    warn = FALSE,
    encoding = "UTF-8"
  )

  latex_overfull <- grep(
    "Overfull \\\\hbox|Overfull \\\\vbox",
    latex_log,
    value = TRUE
  )

  if (length(latex_overfull)) {
    stop(
      "LaTeX produced overfull boxes:\n",
      paste(latex_overfull, collapse = "\n"),
      call. = FALSE
    )
  }

  figures <- file.path(
    "figures",
    c(
      "architecture-figure-1.pdf",
      "resampling-design-figure-1.pdf",
      "performance-comparison-figure-1.pdf",
      "calibration-figure-1.pdf",
      "threshold-abstention-figure-1.pdf",
      "shift-figure-1.pdf"
    )
  )
  stopifnot(
    all(file.exists(figures)),
    all(file.info(figures)$size > 0L)
  )

  figure_pages <- vapply(
    figures,
    function(path) {
      info <- pdftools::pdf_info(path)
      as.integer(info$pages)
    },
    integer(1L)
  )

  stopifnot(
    all(figure_pages >= 1L)
  )

  pdf_text <- paste(pdftools::pdf_text("article.pdf"), collapse = "\n")
  stopifnot(
    !grepl("??", pdf_text, fixed = TRUE),
    grepl("gp3ml", pdf_text, fixed = TRUE),
    grepl("scikit-learn", pdf_text, fixed = TRUE),
    grepl("Limitations and disadvantages", pdf_text, fixed = TRUE)
  )

  pages <- pdftools::pdf_info("article.pdf")$pages

  validation <- c(
    "# gp3ml JSS draft validation",
    "",
    paste0("Generated: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    "",
    "| Check | Status |",
    "|---|---|",
    "| gp3ml 0.3.0 installed from repository source | passed |",
    "| code.R spun to code.html | passed |",
    "| Six manuscript figures reproduced | passed |",
    "| JSS LaTeX compiled with pdfLaTeX | passed |",
    "| Bibliography resolved | passed |",
    "| scikit-learn comparison present | passed |",
    "| Limitations/disadvantages section present | passed |",
    "",
    paste0("PDF pages: ", pages)
  )
  writeLines(validation, "VALIDATION.md", useBytes = TRUE)

  cat(
    "\nPASS: first substantive JSS draft rendered successfully.",
    "\nPDF pages: ", pages,
    "\nPDF: ", normalizePath("article.pdf", winslash = "/"),
    "\nReplication output: ",
    normalizePath(html_candidates[file.exists(html_candidates)][1L], winslash = "/"),
    "\n",
    sep = ""
  )
}

main()
