# Validate the manuscript and current gp3ml repository in a clean process.
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  repo_root <- if (length(args)) {
    normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(".", winslash = "/", mustWork = TRUE)
  }
  paper_dir <- file.path(repo_root, "paper")
  validation_path <- file.path(paper_dir, "VALIDATION.md")
  test_plot_path <- file.path(repo_root, "tests", "testthat", "Rplots.pdf")
  test_plot_preexisting <- file.exists(test_plot_path)
  on.exit({
    if (!test_plot_preexisting && file.exists(test_plot_path)) {
      unlink(test_plot_path, force = TRUE)
    }
  }, add = TRUE)

  status_rows <- list()

  record <- function(check, status, detail) {
    status_rows[[length(status_rows) + 1L]] <<- data.frame(
      check = check,
      status = status,
      detail = detail,
      stringsAsFactors = FALSE
    )
  }
  run <- function(check, expr, unavailable = FALSE) {
    tryCatch(
      {
        force(expr)
        record(check, "passed", "Completed without error.")
      },
      error = function(e) {
        record(
          check,
          if (unavailable) "unavailable optional diagnostic" else "failed",
          conditionMessage(e)
        )
      }
    )
  }

  run("Repository identification", {
    d <- read.dcf(file.path(repo_root, "DESCRIPTION"))
    stopifnot(
      identical(unname(d[1L, "Package"]), "gp3ml"),
      identical(unname(d[1L, "Version"]), "0.3.0")
    )
  })
  run(
    "Manuscript source present",
    stopifnot(file.exists(file.path(paper_dir, "gp3ml-paper.Rmd")))
  )
  run(
    "Bibliography present",
    stopifnot(file.exists(file.path(paper_dir, "references.bib")))
  )
  run(
    "Evidence table present",
    stopifnot(file.exists(file.path(paper_dir, "data", "evidence.csv")))
  )

  required <- c(
    "rmarkdown", "knitr", "rjtools", "kableExtra", "openssl", "devtools",
    "pkgdown", "testthat", "callr", "pdftools"
  )
  missing <- required[!vapply(
    required,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )]
  run("Manuscript dependencies", {
    if (length(missing)) {
      stop("Missing packages: ", paste(missing, collapse = ", "))
    }
  })

  lib <- tempfile("gp3ml-paper-validation-lib-")
  dir.create(lib, recursive = TRUE)
  on.exit(unlink(lib, recursive = TRUE, force = TRUE), add = TRUE)
  install_ok <- FALSE
  run("Temporary installation of current gp3ml source", {
    r_bin <- file.path(R.home("bin"), "R")
    install <- system2(
      r_bin,
      c(
        "CMD", "INSTALL", "--no-multiarch", "--with-keep.source",
        paste0("--library=", shQuote(lib)),
        shQuote(repo_root)
      ),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(install, "status")
    if (is.null(status)) status <- 0L
    if (!identical(as.integer(status), 0L)) {
      stop(paste(c("Installation failed:", install), collapse = "\n"))
    }
    install_ok <- TRUE
  })

  old_lib <- .libPaths()
  on.exit(.libPaths(old_lib), add = TRUE)
  if (install_ok) .libPaths(c(lib, old_lib))

  run("Installed version identity", {
    stopifnot(install_ok)
    stopifnot(
      identical(
        as.character(utils::packageVersion("gp3ml", lib.loc = lib)),
        "0.3.0"
      )
    )
  })

  run("R source syntax", {
    r_files <- list.files(
      file.path(paper_dir, "R"),
      pattern = "\\.R$",
      full.names = TRUE
    )
    invisible(lapply(r_files, parse))
    extracted <- tempfile(fileext = ".R")
    knitr::purl(
      file.path(paper_dir, "gp3ml-paper.Rmd"),
      output = extracted,
      documentation = 0L,
      quiet = TRUE
    )
    parse(extracted)
  })

  render_outputs <- character()
  run("R Journal manuscript render", {
    stopifnot(install_ok)
    Sys.setenv(
      GP3ML_REPO_ROOT = repo_root,
      GP3ML_PAPER_LIB = lib
    )

    out_dir <- file.path(paper_dir, "output")
    duplicate_output_tex <- file.path(out_dir, "gp3ml-paper.tex")
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

    root_tex <- file.path(paper_dir, "gp3ml-paper.tex")
    figure_dir <- file.path(paper_dir, "gp3ml-paper_files", "figure-latex")
    expected_figures <- file.path(
      figure_dir,
      c(
        "architecture-figure-1.pdf",
        "resampling-design-figure-1.pdf",
        "performance-comparison-figure-1.pdf",
        "calibration-figure-1.pdf",
        "threshold-abstention-figure-1.pdf",
        "shift-figure-1.pdf"
      )
    )
    root_pdf <- file.path(paper_dir, "gp3ml-paper.pdf")
    root_bbl <- file.path(paper_dir, "RJwrapper.bbl")

    # rjtools constructs RJwrapper.tex and compiles it in the article
    # working directory. The PDF therefore must be rendered there rather
    # than redirected through output_dir.
    stale_pdf_products <- c(root_tex, root_pdf, root_bbl, duplicate_output_tex)
    stale_pdf_products <- stale_pdf_products[file.exists(stale_pdf_products)]
    if (length(stale_pdf_products)) {
      unlink(stale_pdf_products, force = TRUE)
    }

    render_started <- Sys.time()

    old_wd <- setwd(paper_dir)
    pdf_render <- tryCatch(
      rmarkdown::render(
        input = "gp3ml-paper.Rmd",
        output_format = "rjtools::rjournal_pdf_article",
        envir = new.env(parent = globalenv()),
        clean = FALSE,
        quiet = FALSE
      ),
      finally = setwd(old_wd)
    )

    stopifnot(
      file.exists(root_tex),
      file.exists(root_pdf),
      file.info(root_tex)$mtime >= render_started - 2,
      file.info(root_pdf)$mtime >= render_started - 2,
      all(file.exists(expected_figures))
    )

    html_render <- rmarkdown::render(
      input = file.path(paper_dir, "gp3ml-paper.Rmd"),
      output_format = "rjtools::rjournal_web_article",
      output_dir = out_dir,
      envir = new.env(parent = globalenv()),
      clean = TRUE,
      quiet = FALSE
    )

    html_path <- file.path(out_dir, "gp3ml-paper.html")

    stopifnot(
      file.exists(html_path),
      file.info(html_path)$size > 0L,
      !file.exists(duplicate_output_tex)
    )

    render_outputs <- c(
      root_pdf,
      root_tex,
      html_path
    )
  })

  run("Self-contained HTML output", {
    html_path <- file.path(paper_dir, "output", "gp3ml-paper.html")
    stopifnot(file.exists(html_path))

    embedded_html <- tempfile(fileext = ".html")
    old_html_wd <- setwd(dirname(html_path))

    tryCatch(
      rmarkdown::pandoc_self_contained_html(
        input = basename(html_path),
        output = embedded_html
      ),
      finally = setwd(old_html_wd)
    )

    stopifnot(
      file.exists(embedded_html),
      file.info(embedded_html)$size > 0L
    )

    stopifnot(
      file.copy(
        embedded_html,
        html_path,
        overwrite = TRUE
      )
    )

    unlink(embedded_html, force = TRUE)

    html_text <- readLines(
      html_path,
      warn = FALSE,
      encoding = "UTF-8"
    )

    stopifnot(
      !any(grepl(
        "gp3ml-paper_files/",
        html_text,
        fixed = TRUE
      )),
      any(grepl(
        "data:",
        html_text,
        fixed = TRUE
      ))
    )
  })

  run("Final citation resolution", {
    source_text <- paste(
      readLines(
        file.path(paper_dir, "gp3ml-paper.Rmd"),
        warn = FALSE,
        encoding = "UTF-8"
      ),
      collapse = "\n"
    )

    source_hits <- gregexpr(
      "(?<![A-Za-z0-9._%+-])@([A-Za-z][A-Za-z0-9:_-]*)",
      source_text,
      perl = TRUE
    )[[1L]]

    source_strings <- regmatches(
      source_text,
      list(source_hits)
    )[[1L]]

    source_keys <- sort(unique(sub("^@", "", source_strings)))

    tex_path <- file.path(paper_dir, "gp3ml-paper.tex")
    stopifnot(file.exists(tex_path))

    tex_text <- paste(
      readLines(tex_path, warn = FALSE, encoding = "UTF-8"),
      collapse = "\n"
    )

    cite_hits <- gregexpr(
      "\\\\cite[a-zA-Z*]*\\{[^}]+\\}",
      tex_text,
      perl = TRUE
    )[[1L]]

    cite_calls <- regmatches(
      tex_text,
      list(cite_hits)
    )[[1L]]

    tex_keys <- sort(unique(trimws(unlist(lapply(
      cite_calls,
      function(x) {
        inside <- sub("^[^{]*\\{([^}]*)\\}$", "\\1", x)
        strsplit(inside, ",", fixed = TRUE)[[1L]]
      }
    )))))

    bib_path <- file.path(paper_dir, "references.bib")
    stopifnot(file.exists(bib_path))

    bib <- readLines(
      bib_path,
      warn = FALSE,
      encoding = "UTF-8"
    )

    bib_entry_lines <- grep(
      "^@[A-Za-z]+\\{[^,]+,",
      bib,
      value = TRUE
    )

    bib_keys <- sort(unique(sub(
      "^@[A-Za-z]+\\{([^,]+),.*$",
      "\\1",
      bib_entry_lines
    )))

    missing_from_tex <- setdiff(source_keys, tex_keys)
    stale_in_tex <- setdiff(tex_keys, source_keys)
    missing_from_bib <- setdiff(tex_keys, bib_keys)

    if (length(missing_from_tex) ||
        length(stale_in_tex) ||
        length(missing_from_bib)) {
      stop(
        paste(
          c(
            if (length(missing_from_tex))
              paste0("Missing from generated TeX: ", paste(missing_from_tex, collapse = ", ")),
            if (length(stale_in_tex))
              paste0("Stale/generated-only TeX keys: ", paste(stale_in_tex, collapse = ", ")),
            if (length(missing_from_bib))
              paste0("Missing from bibliography: ", paste(missing_from_bib, collapse = ", "))
          ),
          collapse = " | "
        )
      )
    }

    pdf_text <- paste(
      pdftools::pdf_text(file.path(paper_dir, "gp3ml-paper.pdf")),
      collapse = "\n"
    )

    if (grepl("(?)", pdf_text, fixed = TRUE)) {
      stop("Final PDF contains an unresolved citation marker: (?)")
    }
  })

  run("R Journal PDF page limit", {
    if (!requireNamespace("pdftools", quietly = TRUE)) stop("pdftools is required for the page-limit check")
    pdf_path <- file.path(paper_dir, "gp3ml-paper.pdf")
    stopifnot(file.exists(pdf_path))
    pages <- pdftools::pdf_info(pdf_path)$pages
    if (pages > 20L) stop("The manuscript is ", pages, " pages; the R Journal maximum is 20.")
  })

  run("R Journal initial checks", {
    if (!requireNamespace("rjtools", quietly = TRUE)) {
      stop("rjtools is not installed")
    }
    if (!length(render_outputs)) {
      stop("The manuscript did not render, so generated output is unavailable")
    }
    old_repos <- getOption("repos")
    on.exit(options(repos = old_repos), add = TRUE)
    cran_repo <- ""
    if (!is.null(old_repos) && length(old_repos) &&
        !is.null(names(old_repos)) && "CRAN" %in% names(old_repos)) {
      cran_repo <- unname(old_repos[["CRAN"]])
    }
    if (!nzchar(cran_repo) || identical(cran_repo, "@CRAN@")) {
      options(repos = c(CRAN = "https://cloud.r-project.org"))
    }
    stale_log <- file.path(paper_dir, "initial_checks.log")
    if (file.exists(stale_log)) unlink(stale_log, force = TRUE)
    old_wd <- setwd(paper_dir)
    checked <- tryCatch(
      {
        check_output <- capture.output(
          checks <- rjtools::initial_check_article(
            path = ".",
            dic = "en_GB",
            pkg = "gp3ml",
            ignore = "gp3ml",
            ask = FALSE,
            logfile = NULL
          ),
          type = "output"
        )
        list(output = check_output, checks = checks)
      },
      finally = setwd(old_wd)
    )
    summary_lines <- checked$output[
      grepl("SUCCESS:", checked$output, fixed = TRUE) &
        grepl("ERROR:", checked$output, fixed = TRUE)
    ]
    error_counts <- integer()
    if (length(summary_lines)) {
      extracted_counts <- sub(
        ".*ERROR:[[:space:]]*([0-9]+).*",
        "\\1",
        summary_lines
      )
      error_counts <- suppressWarnings(as.integer(extracted_counts))
      error_counts <- error_counts[!is.na(error_counts)]
    }
    detailed_error_lines <- checked$output[
      grepl("ERROR:", checked$output, fixed = TRUE) &
        !grepl("SUCCESS:", checked$output, fixed = TRUE)
    ]
    if (any(error_counts > 0L) || length(detailed_error_lines)) {
      details <- c(
        if (length(error_counts)) {
          paste0("ERROR count: ", max(error_counts))
        } else {
          character()
        },
        detailed_error_lines
      )
      stop(
        "One or more R Journal checks reported ERROR: ",
        paste(unique(details), collapse = " | ")
      )
    }
  }, unavailable = FALSE)

  run("Complete package tests", {
    if (!requireNamespace("callr", quietly = TRUE) ||
        !requireNamespace("devtools", quietly = TRUE)) {
      stop("callr and devtools are required")
    }
    callr::r(
      function(path) {
        grDevices::pdf(file = NULL)
        on.exit({
          if (grDevices::dev.cur() > 1L) grDevices::dev.off()
        }, add = TRUE)
        devtools::test(pkg = path, reporter = "summary", stop_on_failure = TRUE)
        TRUE
      },
      args = list(path = repo_root),
      show = TRUE
    )
  })

  run("pkgdown configuration", {
    if (!requireNamespace("pkgdown", quietly = TRUE)) {
      stop("pkgdown is not installed")
    }
    pkgdown::check_pkgdown(pkg = repo_root)
  })

  run("API contract audit", {
    stopifnot(install_ok)
    contracts <- gp3ml::gp3ml_api_contracts()
    audit <- gp3ml::audit_gp3ml_api_stability(contracts)
    stopifnot(
      identical(audit$status, "pass"),
      nrow(audit$differences) == 0L,
      sum(contracts$exports$stability == "stable") == 71L,
      sum(contracts$exports$stability == "experimental") == 56L,
      nrow(contracts$classes) == 38L
    )
  })

  run("Executable leakage and partition audit", {
    stopifnot(install_ok)
    case_env <- new.env(parent = globalenv())
    case_env$repo_root <- repo_root
    case_env$paper_dir <- paper_dir
    sys.source(file.path(paper_dir, "R", "helpers.R"), envir = case_env)
    suppressPackageStartupMessages(
      eval(quote(library(gp3ml)), envir = case_env)
    )
    sys.source(file.path(paper_dir, "R", "case-study.R"), envir = case_env)
    stopifnot(
      identical(case_env$group_audit$status, "pass"),
      identical(case_env$cross_audit$status, "pass"),
      identical(case_env$analysis_plan_validation$status, "pass"),
      identical(case_env$decision_validation$status, "pass"),
      !identical(case_env$artifact_validation$status, "fail"),
      identical(case_env$api_stability$status, "pass"),
      length(intersect(
        case_env$policy_development_participants,
        case_env$policy_audit_participants
      )) == 0L
    )
  })

  run("Scope-language audit", {
    text <- paste(
      readLines(file.path(paper_dir, "gp3ml-paper.Rmd"), warn = FALSE),
      collapse = "\n"
    )
    prohibited_positive_claims <- c(
      "infers emotion",
      "infers stress",
      "diagnoses",
      "identifies a person",
      "automatically finds the best model",
      "eliminates bias",
      "ensures validity"
    )
    lower <- tolower(text)
    stopifnot(!any(vapply(
      prohibited_positive_claims,
      grepl,
      logical(1),
      x = lower,
      fixed = TRUE
    )))
  })

  run("Repository-relative manuscript paths", {
    text_files <- c(
      file.path(paper_dir, "gp3ml-paper.Rmd"),
      list.files(file.path(paper_dir, "R"), pattern = "\\.R$", full.names = TRUE)
    )
    text <- paste(unlist(lapply(text_files, readLines, warn = FALSE)), collapse = "\n")
    stopifnot(!grepl("[A-Za-z]:[/\\\\]Users[/\\\\]", text, perl = TRUE))
  })

  run("Submission auxiliary-file cleanup", {
    auxiliary <- list.files(paper_dir, pattern = "\\.(log|aux|out)$", full.names = TRUE, ignore.case = TRUE)
    if (length(auxiliary)) unlink(auxiliary, force = TRUE)
    remaining <- list.files(paper_dir, pattern = "\\.(log|aux|out)$", full.names = TRUE, ignore.case = TRUE)
    stopifnot(length(remaining) == 0L)
  })

  run("Git working-tree boundary", {
    git <- Sys.which("git")
    if (!nzchar(git)) stop("git is unavailable")
    status <- system2(
      git,
      c("-C", shQuote(repo_root), "status", "--short"),
      stdout = TRUE,
      stderr = TRUE
    )
    unexpected <- status[!grepl("^.. paper/", status)]
    if (length(unexpected)) {
      stop("Unexpected repository changes: ", paste(unexpected, collapse = " | "))
    }
  })

  results <- do.call(rbind, status_rows)
  escape_cell <- function(x) gsub("\\|", "\\\\|", x)
  lines <- c(
    "# gp3ml paper validation",
    "",
    paste0("Generated: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    "",
    "| Check | Status | Detail |",
    "|---|---|---|",
    apply(results, 1L, function(z) {
      paste0(
        "| ", escape_cell(z[[1L]]),
        " | ", z[[2L]],
        " | ", escape_cell(z[[3L]]), " |"
      )
    }),
    "",
    paste(
      "A failed core check is not converted into a pass.",
      "Missing optional tooling is reported as unavailable."
    )
  )
  writeLines(lines, validation_path, useBytes = TRUE)
  print(results, row.names = FALSE)
  if (any(results$status == "failed")) quit(status = 1L)
  invisible(results)
}

if (sys.nframe() == 0L) main()
