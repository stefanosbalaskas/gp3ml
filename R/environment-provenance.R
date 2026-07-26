#' Capture a reproducibility environment record
#'
#' @param packages Packages to record. Defaults to gp3ml and currently loaded namespaces.
#' @param root Repository/project root used to capture Git SHA.
#' @param include_renv Whether to record an existing `renv.lock` hash.
#' @return A `gp3ml_environment_record`.
#' @export
capture_gazepoint_environment <- function(
    packages = unique(c("gp3ml", loadedNamespaces())),
    root = ".",
    include_renv = FALSE) {
  versions <- vapply(packages, .gp3ml_ng_package_version, character(1))
  versions <- versions[!is.na(versions)]
  renv_hash <- NA_character_
  if (isTRUE(include_renv)) {
    lock <- file.path(root, "renv.lock")
    if (file.exists(lock)) renv_hash <- .gp3ml_ng_hash_file(lock)
  }
  si <- utils::sessionInfo()
  structure(
    list(
      R_version = R.version.string,
      R_platform = R.version$platform,
      OS = paste(Sys.info()[c("sysname","release","version")], collapse=" "),
      BLAS = si$BLAS %||% NA_character_,
      LAPACK = si$LAPACK %||% NA_character_,
      RNGkind = RNGkind(),
      repositories = getOption("repos"),
      package_versions = versions,
      gp3ml_git_sha = .gp3ml_ng_git_sha(root),
      renv_lock_sha256 = renv_hash
    ),
    class="gp3ml_environment_record"
  )
}

#' Compare two environment records
#' @param reference Reference environment.
#' @param current Current environment.
#' @return A `gp3ml_environment_comparison`.
#' @export
compare_gazepoint_environments <- function(reference, current) {
  if (!inherits(reference, "gp3ml_environment_record") ||
      !inherits(current, "gp3ml_environment_record"))
    .gp3ml_ng_stop("Both objects must be gp3ml environment records.")
  pkgs <- sort(unique(c(names(reference$package_versions), names(current$package_versions))))
  tab <- data.frame(
    package=pkgs,
    reference=unname(reference$package_versions[pkgs]),
    current=unname(current$package_versions[pkgs]),
    stringsAsFactors=FALSE
  )
  tab$status <- ifelse(is.na(tab$reference) | is.na(tab$current), "review",
                       ifelse(tab$reference == tab$current, "pass", "review"))
  core <- data.frame(
    component=c("R_version","R_platform","gp3ml_git_sha","renv_lock_sha256"),
    reference=vapply(c("R_version","R_platform","gp3ml_git_sha","renv_lock_sha256"),
                     function(nm) as.character(reference[[nm]]), character(1)),
    current=vapply(c("R_version","R_platform","gp3ml_git_sha","renv_lock_sha256"),
                   function(nm) as.character(current[[nm]]), character(1)),
    stringsAsFactors=FALSE
  )
  core$status <- ifelse(
    is.na(core$reference) & is.na(core$current),
    "pass",
    ifelse(
      is.na(core$reference) | is.na(core$current),
      "review",
      ifelse(
        core$reference == core$current,
        "pass",
        "review"
      )
    )
  )
  structure(list(status=.gp3ml_ng_status(c(tab$status, core$status)),
                 packages=tab, core=core),
            class="gp3ml_environment_comparison")
}

#' Validate the current environment against a reference record
#' @param reference Reference environment record.
#' @param root Project root.
#' @param include_renv Whether to compare renv lock hashes.
#' @return An environment comparison.
#' @export
validate_gazepoint_environment <- function(reference, root=".", include_renv=FALSE) {
  current <- capture_gazepoint_environment(
    packages=names(reference$package_versions),
    root=root,
    include_renv=include_renv
  )
  compare_gazepoint_environments(reference, current)
}

#' Plot an environment comparison
#' @param x An environment comparison.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_environment_comparison
#' @export
plot.gp3ml_environment_comparison <- function(x, ...) {

  values <- c(
    pass =
      sum(
        x$packages$status == "pass",
        na.rm = TRUE
      ) +
      sum(
        x$core$status == "pass",
        na.rm = TRUE
      ),

    review =
      sum(
        x$packages$status == "review",
        na.rm = TRUE
      ) +
      sum(
        x$core$status == "review",
        na.rm = TRUE
      )
  )

  graphics::barplot(
    values,
    ylab = "Checks",
    main = "Environment reproducibility comparison",
    ...
  )

  invisible(x)
}
