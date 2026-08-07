# Render the R Journal manuscript from a clean temporary installation.

main <- function(args = commandArgs(trailingOnly = TRUE)) {

  repo_root <- if (length(args)) {
    normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(".", winslash = "/", mustWork = TRUE)
  }

  description_path <- file.path(repo_root, "DESCRIPTION")
  stopifnot(file.exists(description_path))

  desc <- read.dcf(description_path)
  stopifnot(
    identical(unname(desc[1L, "Package"]), "gp3ml")
  )

  required <- c(
    "rmarkdown",
    "knitr",
    "rjtools",
    "kableExtra",
    "openssl"
  )

  missing <- required[!vapply(
    required,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )]

  if (length(missing)) {
    stop(
      "Install manuscript dependencies: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  paper_dir <- file.path(repo_root, "paper")
  rmd_path <- file.path(paper_dir, "gp3ml-paper.Rmd")
  out_dir <- file.path(paper_dir, "output")
  duplicate_output_tex <- file.path(out_dir, "gp3ml-paper.tex")

  stopifnot(
    file.exists(rmd_path),
    requireNamespace("rmarkdown", quietly = TRUE),
    requireNamespace("rjtools", quietly = TRUE)
  )

  # Remove stale TeX left by historical output-directory renders.
  if (file.exists(duplicate_output_tex)) {
    unlink(duplicate_output_tex, force = TRUE)
  }

  stopifnot(!file.exists(duplicate_output_tex))

  dir.create(
    out_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  lib <- tempfile("gp3ml-paper-render-lib-")
  dir.create(lib, recursive = TRUE)
  on.exit(unlink(lib, recursive = TRUE, force = TRUE), add = TRUE)

  r_bin <- file.path(R.home("bin"), "R")

  install <- system2(
    r_bin,
    c(
      "CMD",
      "INSTALL",
      "--no-multiarch",
      "--with-keep.source",
      paste0("--library=", shQuote(lib)),
      shQuote(repo_root)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  install_status <- attr(install, "status")
  if (is.null(install_status)) install_status <- 0L

  if (!identical(as.integer(install_status), 0L)) {
    stop(
      paste(c("Installation failed:", install), collapse = "\n"),
      call. = FALSE
    )
  }

  old_lib <- .libPaths()
  on.exit(.libPaths(old_lib), add = TRUE)
  .libPaths(c(lib, old_lib))

  stopifnot(
    identical(
      as.character(utils::packageVersion("gp3ml", lib.loc = lib)),
      unname(desc[1L, "Version"])
    )
  )

  Sys.setenv(
    GP3ML_REPO_ROOT = repo_root,
    GP3ML_PAPER_LIB = lib
  )

  root_pdf <- file.path(paper_dir, "gp3ml-paper.pdf")
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

  render_started <- Sys.time()

  # rjtools builds RJwrapper.tex in the article working directory.
  # Keep the PDF and generated TeX there so the wrapper always compiles
  # the TeX produced by this render.
  old_wd <- setwd(paper_dir)

  pdf_result <- tryCatch(
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
    file.exists(root_pdf),
    file.exists(root_tex),
    file.info(root_pdf)$mtime >= render_started - 2,
    file.info(root_tex)$mtime >= render_started - 2,
    all(file.exists(expected_figures))
  )

  # The web article can safely be directed to paper/output/.
  html_result <- rmarkdown::render(
    input = rmd_path,
    output_format = "rjtools::rjournal_web_article",
    output_dir = out_dir,
    envir = new.env(parent = globalenv()),
    clean = TRUE,
    quiet = FALSE
  )

  html_path <- file.path(out_dir, "gp3ml-paper.html")

  stopifnot(
    file.exists(html_path),
    file.info(html_path)$size > 0L
  )

  # Distill/rjtools can leave linked dependencies despite the YAML
  # self-contained request, so post-process the actual HTML artefact.
  embedded_html <- tempfile(
    "gp3ml-paper-self-contained-",
    tmpdir = out_dir,
    fileext = ".html"
  )

  old_html_wd <- setwd(out_dir)

  tryCatch(
    rmarkdown::pandoc_self_contained_html(
      input = basename(html_path),
      output = basename(embedded_html)
    ),
    finally = setwd(old_html_wd)
  )

  stopifnot(
    file.exists(embedded_html),
    file.info(embedded_html)$size > 0L,
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


  stopifnot(
    !file.exists(duplicate_output_tex)
  )

  cat(
    "PASS: R Journal manuscript rendered from current gp3ml source.\n",
    "PDF: ", normalizePath(root_pdf, winslash = "/"), "\n",
    "TeX: ", normalizePath(root_tex, winslash = "/"), "\n",
    "HTML: ", normalizePath(html_path, winslash = "/"), "\n",
    sep = ""
  )

  invisible(c(
    pdf = root_pdf,
    tex = root_tex,
    html = html_path
  ))
}

if (sys.nframe() == 0L) main()
