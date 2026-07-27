#' Write SHA-256 checksums for release artifacts
#' @param files Release artifact files.
#' @param path Output checksum manifest.
#' @return A `gp3ml_release_checksum_manifest`.
#' @export
write_gazepoint_release_checksums <- function(files, path="SHA256SUMS.csv") {
  .gp3ml_ng_require("openssl")
  files <- as.character(files)
  if (any(!file.exists(files))) .gp3ml_ng_stop("Every release artifact must exist.")
  tab <- data.frame(
    file=basename(files),
    sha256=vapply(files, .gp3ml_ng_hash_file, character(1)),
    size=vapply(files, function(x) unname(file.info(x)$size), numeric(1)),
    stringsAsFactors=FALSE
  )
  utils::write.csv(tab, path, row.names=FALSE)
  structure(list(path=normalizePath(path, winslash="/", mustWork=TRUE), checksums=tab),
            class="gp3ml_release_checksum_manifest")
}

#' Validate SHA-256 release checksums
#' @param manifest Checksum manifest or path.
#' @param directory Directory containing artifacts.
#' @return A validation object.
#' @export
validate_gazepoint_release_checksums <- function(manifest, directory=".") {
  .gp3ml_ng_require("openssl")
  tab <- if (inherits(manifest, "gp3ml_release_checksum_manifest")) manifest$checksums
  else utils::read.csv(manifest, stringsAsFactors=FALSE)
  tab$exists <- file.exists(file.path(directory, tab$file))
  tab$actual_sha256 <- vapply(seq_len(nrow(tab)), function(i) {
    target <- file.path(directory, tab$file[[i]])
    if (!file.exists(target)) NA_character_ else .gp3ml_ng_hash_file(target)
  }, character(1))
  tab$status <- ifelse(tab$exists & tab$sha256 == tab$actual_sha256, "pass", "fail")
  structure(list(status=.gp3ml_ng_status(tab$status), files=tab),
            class="gp3ml_release_checksum_validation")
}

#' Plot release checksum validation
#' @param x Release checksum validation.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_release_checksum_validation
#' @export
plot.gp3ml_release_checksum_validation <- function(x, ...) {
  values <- c(pass=sum(x$files$status=="pass"), fail=sum(x$files$status=="fail"))
  graphics::barplot(values, ylab="Artifacts", main="Release checksum validation", ...)
  invisible(x)
}
