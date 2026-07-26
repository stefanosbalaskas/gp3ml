
.gp3ml_timestamp <- function() {
  if (isTRUE(getOption("gp3ml.reproducible_examples", FALSE))) {
    return("<timestamp>")
  }
  format(Sys.time(), tz = "UTC", usetz = TRUE)
}

.gp3ml_session_info <- function() {
  if (isTRUE(getOption("gp3ml.reproducible_examples", FALSE))) {
    return(c(
      "R version <normalized>",
      "Platform: <normalized>",
      "Session details suppressed for deterministic documentation output."
    ))
  }
  utils::capture.output(utils::sessionInfo())
}

.gp3ml_repro_patterns <- function() {
  list(
    r_temp_directory = "Rtmp[A-Za-z0-9]+",
    windows_temp_path = "(?i)[A-Z]:[/\\\\][^\\r\\n]*AppData[/\\\\]Local[/\\\\]Temp[^\\r\\n <>'\"]*",
    unix_temp_path = "/tmp/Rtmp[^\\r\\n <>'\"]*",
    memory_address = "0x[0-9A-Fa-f]{6,}",
    generated_timestamp = "(?i)Generated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}"
  )
}

#' Normalize volatile text in generated research artifacts
#'
#' @param x Character vector.
#' @param project_path Optional project path to replace by `<PROJECT>`.
#'
#' @return Character vector with volatile runtime fragments normalized.
#' @export
normalize_gazepoint_artifact_text <- function(x, project_path = NULL) {
  out <- as.character(x)

  if (!is.null(project_path) && nzchar(project_path)) {
    normalized_project <- normalizePath(
      project_path,
      winslash = "/",
      mustWork = FALSE
    )
    out <- gsub(
      normalized_project,
      "<PROJECT>",
      out,
      fixed = TRUE
    )
    out <- gsub(
      gsub("/", "\\\\", normalized_project, fixed = TRUE),
      "<PROJECT>",
      out,
      fixed = TRUE
    )
  }

  patterns <- .gp3ml_repro_patterns()
  replacements <- c(
    r_temp_directory = "<RTMP>",
    windows_temp_path = "<TEMP_PATH>",
    unix_temp_path = "<TEMP_PATH>",
    memory_address = "<ADDRESS>",
    generated_timestamp = "Generated: <timestamp>"
  )

  for (name in names(patterns)) {
    out <- gsub(
      patterns[[name]],
      replacements[[name]],
      out,
      perl = TRUE
    )
  }

  out
}

#' Audit generated artifacts for volatile output
#'
#' @param paths Files or directories to audit.
#' @param recursive Whether directories are searched recursively.
#' @param extensions Text-file extensions to inspect.
#'
#' @return A `gp3ml_reproducibility_audit`.
#' @export
audit_gazepoint_reproducibility <- function(
  paths,
  recursive = TRUE,
  extensions = c(
    "R", "Rmd", "Rd", "md", "txt", "html",
    "json", "csv", "yml", "yaml"
  )
) {
  if (!length(paths)) .gp3ml_stop("Supply at least one file or directory.")

  files <- unlist(lapply(paths, function(path) {
    if (dir.exists(path)) {
      list.files(
        path,
        recursive = recursive,
        full.names = TRUE,
        all.files = FALSE
      )
    } else if (file.exists(path)) {
      path
    } else {
      character()
    }
  }), use.names = FALSE)

  ext <- tools::file_ext(files)
  files <- sort(unique(files[tolower(ext) %in% tolower(extensions)]))

  patterns <- .gp3ml_repro_patterns()
  findings <- list()

  for (path in files) {
    lines <- tryCatch(
      readLines(path, warn = FALSE, encoding = "UTF-8"),
      error = function(e) character()
    )
    if (!length(lines)) next

    for (pattern_name in names(patterns)) {
      hit <- grepl(patterns[[pattern_name]], lines, perl = TRUE)
      if (any(hit)) {
        idx <- which(hit)
        findings[[length(findings) + 1L]] <- data.frame(
          path = gsub("\\\\", "/", path),
          line = idx,
          issue = pattern_name,
          excerpt = substr(
            normalize_gazepoint_artifact_text(lines[idx]),
            1L,
            180L
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  finding_table <- if (length(findings)) {
    do.call(rbind, findings)
  } else {
    data.frame(
      path = character(),
      line = integer(),
      issue = character(),
      excerpt = character(),
      stringsAsFactors = FALSE
    )
  }
  row.names(finding_table) <- NULL

  summary <- if (nrow(finding_table)) {
    as.data.frame(table(finding_table$issue), stringsAsFactors = FALSE)
  } else {
    data.frame(
      Var1 = character(),
      Freq = integer(),
      stringsAsFactors = FALSE
    )
  }
  names(summary) <- c("issue", "n")

  structure(
    list(
      status = if (nrow(finding_table)) "review" else "pass",
      files_scanned = length(files),
      findings = finding_table,
      summary = summary
    ),
    class = "gp3ml_reproducibility_audit"
  )
}

#' Write a reproducibility-hardening audit
#'
#' @param audit A `gp3ml_reproducibility_audit`.
#' @param directory Destination directory.
#' @param prefix File prefix.
#' @param overwrite Whether existing files may be replaced.
#'
#' @return Named paths.
#' @export
write_gazepoint_reproducibility_audit <- function(
  audit,
  directory = ".",
  prefix = "gp3ml_reproducibility_audit",
  overwrite = FALSE
) {
  if (!inherits(audit, "gp3ml_reproducibility_audit")) {
    .gp3ml_stop("`audit` must be created by audit_gazepoint_reproducibility().")
  }
  .gp3ml_write_tables(
    list(
      summary = audit$summary,
      findings = audit$findings
    ),
    directory = directory,
    prefix = prefix,
    overwrite = overwrite
  )
}

#' Evaluate code with deterministic documentation-output settings
#'
#' @param code Expression to evaluate.
#'
#' @return The value of `code`.
#' @export
with_gazepoint_reproducible_output <- function(code) {
  old <- options(gp3ml.reproducible_examples = TRUE)
  on.exit(options(old), add = TRUE)
  force(code)
}

#' @method print gp3ml_reproducibility_audit
#' @export
print.gp3ml_reproducibility_audit <- function(x, ...) {
  cat(
    " gp3ml reproducibility audit: ",
    x$status,
    " (",
    x$files_scanned,
    " files, ",
    nrow(x$findings),
    " findings)\n",
    sep = ""
  )
  invisible(x)
}

#' Plot a reproducibility-hardening audit
#'
#' @param x A `gp3ml_reproducibility_audit`.
#' @param ... Additional graphical parameters.
#'
#' @method plot gp3ml_reproducibility_audit
#' @export
plot.gp3ml_reproducibility_audit <- function(x, ...) {
  if (!inherits(x, "gp3ml_reproducibility_audit")) {
    .gp3ml_stop("`x` must be a gp3ml reproducibility audit.")
  }
  if (!nrow(x$summary)) {
    graphics::plot.new()
    graphics::title(main = "No volatile artifact output detected")
    return(invisible(x))
  }
  values <- x$summary$n
  names(values) <- x$summary$issue
  graphics::barplot(
    values,
    las = 2,
    ylab = "Findings",
    main = paste("Reproducibility audit:", x$status),
    ...
  )
  invisible(x)
}
