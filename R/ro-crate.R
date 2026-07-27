#' Write a minimal RO-Crate-oriented research object
#'
#' This helper writes a conservative RO-Crate-oriented JSON-LD metadata file and
#' SHA-256 file hashes. It does not claim formal RO-Crate conformance; use an
#' independent validator when formal conformance is required.
#'
#' @param path Output directory.
#' @param files Named or unnamed character vector of files to include.
#' @param name Research-object name.
#' @param description Description.
#' @param creator_name Creator name.
#' @param creator_orcid Optional ORCID URI or identifier.
#' @param license License URI or label.
#' @param doi Optional DOI.
#' @param copy_files Whether to copy files into the crate directory.
#' @return A `gp3ml_ro_crate`.
#' @export
write_gazepoint_ro_crate <- function(
    path,
    files,
    name,
    description,
    creator_name,
    creator_orcid = NULL,
    license = "MIT",
    doi = NULL,
    copy_files = TRUE) {
  .gp3ml_ng_require("jsonlite")
  .gp3ml_ng_require("openssl")
  path <- normalizePath(path, winslash="/", mustWork=FALSE)
  dir.create(path, recursive=TRUE, showWarnings=FALSE)
  files <- as.character(files)
  if (any(!file.exists(files))) .gp3ml_ng_stop("All RO-Crate source files must exist.")
  entities <- vector("list", length(files))
  manifest <- vector("list", length(files))
  for (i in seq_along(files)) {
    src <- normalizePath(files[[i]], winslash="/", mustWork=TRUE)
    rel <- basename(src)
    dest <- file.path(path, rel)
    if (isTRUE(copy_files)) file.copy(src, dest, overwrite=TRUE)
    target <- if (isTRUE(copy_files)) dest else src
    hash <- .gp3ml_ng_hash_file(target)
    size <- file.info(target)$size
    entities[[i]] <- list(
      "@id"=rel, "@type"="File", name=rel,
      contentSize=unname(size), sha256=hash
    )
    manifest[[i]] <- data.frame(file=rel, sha256=hash, size=unname(size),
                                stringsAsFactors=FALSE)
  }
  creator_id <- if (!is.null(creator_orcid)) {
    if (grepl("^https?://", creator_orcid)) creator_orcid else paste0("https://orcid.org/", creator_orcid)
  } else "#creator"
  graph <- c(
    list(
      list("@id"="ro-crate-metadata.json", "@type"="CreativeWork",
           about=list("@id"="./"),
           conformsTo=list("@id"="https://w3id.org/ro/crate/1.2")),
      list("@id"="./", "@type"="Dataset", name=name, description=description,
           license=license, identifier=doi,
           creator=list("@id"=creator_id),
           hasPart=lapply(entities, function(z) list("@id"=z[["@id"]]))),
      list("@id"=creator_id, "@type"="Person", name=creator_name)
    ),
    entities
  )
  metadata <- list("@context"="https://w3id.org/ro/crate/1.2/context", "@graph"=graph)
  meta_path <- file.path(path, "ro-crate-metadata.json")
  jsonlite::write_json(metadata, meta_path, pretty=TRUE, auto_unbox=TRUE, null="null")
  manifest_df <- do.call(rbind, manifest)
  manifest_path <- file.path(path, "sha256-manifest.csv")
  utils::write.csv(manifest_df, manifest_path, row.names=FALSE)
  structure(
    list(path=path, metadata=meta_path, manifest=manifest_path,
         file_manifest=manifest_df,
         note="RO-Crate-oriented export; run an independent RO-Crate validator for formal conformance."),
    class="gp3ml_ro_crate"
  )
}

#' Validate a gp3ml RO-Crate-oriented export
#' @param path Crate directory or `gp3ml_ro_crate`.
#' @return A validation object.
#' @export
validate_gazepoint_ro_crate <- function(path) {
  .gp3ml_ng_require("jsonlite")
  .gp3ml_ng_require("openssl")
  if (inherits(path, "gp3ml_ro_crate")) path <- path$path
  meta <- file.path(path, "ro-crate-metadata.json")
  manifest <- file.path(path, "sha256-manifest.csv")
  checks <- data.frame(check=c("metadata","manifest","context","root_dataset","hashes"),
                       status="pass", detail="", stringsAsFactors=FALSE)
  if (!file.exists(meta)) checks$status[checks$check=="metadata"] <- "fail"
  if (!file.exists(manifest)) checks$status[checks$check=="manifest"] <- "fail"
  if (file.exists(meta)) {
    obj <- jsonlite::read_json(meta, simplifyVector=FALSE)
    if (is.null(obj[["@context"]]) || !grepl("ro/crate/1.2", obj[["@context"]], fixed=TRUE))
      checks$status[checks$check=="context"] <- "fail"
    ids <- vapply(obj[["@graph"]] %||% list(), function(z) z[["@id"]] %||% "", character(1))
    if (!"./" %in% ids) checks$status[checks$check=="root_dataset"] <- "fail"
  }
  if (file.exists(manifest)) {
    man <- utils::read.csv(manifest, stringsAsFactors=FALSE)
    bad <- vapply(seq_len(nrow(man)), function(i) {
      target <- file.path(path, man$file[[i]])
      !file.exists(target) || !identical(.gp3ml_ng_hash_file(target), man$sha256[[i]])
    }, logical(1))
    if (any(bad)) checks$status[checks$check=="hashes"] <- "fail"
  }
  structure(
    list(status=.gp3ml_ng_status(checks$status), checks=checks,
         note="This validates gp3ml's minimal export and hashes, not full RO-Crate conformance."),
    class="gp3ml_ro_crate_validation"
  )
}

#' Plot RO-Crate validation
#' @param x A `gp3ml_ro_crate_validation`.
#' @param ... Additional arguments passed to `graphics::barplot()`.
#' @method plot gp3ml_ro_crate_validation
#' @export
plot.gp3ml_ro_crate_validation <- function(x, ...) {
  values <- c(pass=sum(x$checks$status=="pass"), fail=sum(x$checks$status=="fail"),
              review=sum(x$checks$status=="review"))
  graphics::barplot(values, ylab="Checks", main="Research-object validation", ...)
  invisible(x)
}
