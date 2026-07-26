.gp3ml_ng_stop <- function(fmt, ...) {
  if (exists(".gp3ml_stop", mode = "function", inherits = TRUE)) {
    .gp3ml_stop(fmt, ...)
  } else {
    stop(sprintf(fmt, ...), call. = FALSE)
  }
}

.gp3ml_ng_require <- function(package, reason = NULL) {
  if (!requireNamespace(package, quietly = TRUE)) {
    suffix <- if (is.null(reason)) "" else paste0(" ", reason)
    .gp3ml_ng_stop("Install optional package `%s` to use this feature.%s", package, suffix)
  }
  invisible(TRUE)
}

.gp3ml_ng_assert_data <- function(x, name = "data") {
  if (!is.data.frame(x)) .gp3ml_ng_stop("`%s` must be a data frame.", name)
  invisible(TRUE)
}

.gp3ml_ng_assert_prob <- function(x, name = "probability") {
  if (!is.numeric(x) || any(!is.finite(x[!is.na(x)])) ||
      any(x[!is.na(x)] < 0 | x[!is.na(x)] > 1)) {
    .gp3ml_ng_stop("`%s` must contain probabilities in [0, 1].", name)
  }
  invisible(TRUE)
}

.gp3ml_ng_status <- function(x) {
  x <- as.character(x)
  if (any(x == "fail", na.rm = TRUE)) "fail" else if (any(x == "review", na.rm = TRUE)) "review" else "pass"
}

.gp3ml_ng_sha256_raw <- function(raw) {
  .gp3ml_ng_require(
    "openssl",
    "SHA-256 is required for cryptographic provenance."
  )

  hash <- openssl::sha256(raw)

  unname(
    unclass(
      as.character(hash)
    )
  )
}

.gp3ml_ng_hash_object <- function(x) {
  .gp3ml_ng_sha256_raw(serialize(x, NULL, version = 3L))
}

.gp3ml_ng_hash_file <- function(path) {
  .gp3ml_ng_require(
    "openssl",
    "SHA-256 is required for cryptographic provenance."
  )

  if (!file.exists(path)) {
    .gp3ml_ng_stop(
      "File does not exist: %s",
      path
    )
  }

  size <- unname(
    file.info(path)$size
  )

  bytes <- readBin(
    path,
    what = "raw",
    n = size
  )

  hash <- openssl::sha256(bytes)

  unname(
    unclass(
      as.character(hash)
    )
  )
}

.gp3ml_ng_quantile <- function(x, probability) {
  x <- x[is.finite(x)]
  if (!length(x)) .gp3ml_ng_stop("No finite conformity scores are available.")
  probability <- max(0, min(1, probability))
  stats::quantile(x, probs = probability, type = 1, names = FALSE, na.rm = TRUE)
}

.gp3ml_ng_md_table <- function(x) {
  if (!is.data.frame(x)) x <- as.data.frame(x, stringsAsFactors = FALSE)
  values <- lapply(x, function(z) {
    z <- as.character(z)
    z[is.na(z)] <- ""
    gsub("\\|", "\\\\|", z)
  })
  x[] <- values
  header <- paste0("| ", paste(names(x), collapse = " | "), " |")
  rule <- paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |")
  rows <- if (nrow(x)) apply(x, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |")) else character()
  c(header, rule, rows)
}

.gp3ml_ng_package_version <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) return(NA_character_)
  as.character(utils::packageVersion(package))
}

.gp3ml_ng_git_sha <- function(root = ".") {
  git <- Sys.which("git")
  if (!nzchar(git)) return(NA_character_)
  out <- tryCatch(
    system2(git, c("-C", normalizePath(root, winslash = "/", mustWork = TRUE), "rev-parse", "HEAD"),
            stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (length(out) == 1L) trimws(out) else NA_character_
}
