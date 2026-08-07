# Render the R Journal manuscript from a clean temporary installation.
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  repo_root <- if (length(args)) {
    normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(".", winslash = "/", mustWork = TRUE)
  }
  stopifnot(file.exists(file.path(repo_root, "DESCRIPTION")))
  desc <- read.dcf(file.path(repo_root, "DESCRIPTION"))
  stopifnot(identical(unname(desc[1L, "Package"]), "gp3ml"))

  required <- c("rmarkdown", "knitr", "rjtools", "openssl")
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

  lib <- tempfile("gp3ml-paper-lib-")
  dir.create(lib, recursive = TRUE)
  on.exit(unlink(lib, recursive = TRUE, force = TRUE), add = TRUE)

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
  cat(install, sep = "\n")
  if (!identical(as.integer(status), 0L)) {
    stop("Temporary installation failed.", call. = FALSE)
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
  out_dir <- file.path(repo_root, "paper", "output")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  outputs <- rmarkdown::render(
    input = file.path(repo_root, "paper", "gp3ml-paper.Rmd"),
    output_format = "all",
    output_dir = out_dir,
    envir = new.env(parent = globalenv()),
    clean = TRUE,
    quiet = FALSE
  )
  cat(
    "Rendered manuscript outputs:\n",
    paste(normalizePath(outputs, winslash = "/", mustWork = TRUE), collapse = "\n"),
    "\n",
    sep = ""
  )
  invisible(outputs)

# >>> R JOURNAL SELF-CONTAINED HTML >>>
html_output <- file.path(paper_dir, "output", "gp3ml-paper.html")
if (file.exists(html_output)) {
  embedded_html <- tempfile(fileext = ".html")
  old_html_wd <- setwd(dirname(html_output))
  tryCatch(
    rmarkdown::pandoc_self_contained_html(
      input = basename(html_output),
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
      html_output,
      overwrite = TRUE
    )
  )
  unlink(embedded_html, force = TRUE)
}
# <<< R JOURNAL SELF-CONTAINED HTML <<<
}

if (sys.nframe() == 0L) main()
