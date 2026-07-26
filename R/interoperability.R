
.gp3ml_interop_sources <- c(
  "gp3tools",
  "gpbiometrics",
  "gp3sequences",
  "study_design",
  "custom"
)

#' Cross-package interoperability contracts
#'
#' Describes a lightweight handoff boundary. Upstream packages remain
#' responsible for their own importing, cleaning, feature derivation, signal
#' processing, sequence processing, and quality control. `gp3ml` receives
#' already prepared observed variables together with explicit provenance.
#'
#' @return A data frame describing supported handoff sources and responsibilities.
#' @export
gp3ml_interop_contracts <- function() {
  data.frame(
    source_package = .gp3ml_interop_sources,
    upstream_responsibility = c(
      "Gazepoint import, validation, gaze/fixation/AOI/transition preparation.",
      "EDA/HR/DIAL/IBI preparation and signal-quality summaries.",
      "Ordered-sequence validation, encoding, summaries, motifs, transitions.",
      "Experimentally assigned labels and prespecified study-design variables.",
      "Externally prepared observed, non-sensitive variables."
    ),
    gp3ml_responsibility = rep(
      "Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.",
      length(.gp3ml_interop_sources)
    ),
    duplicates_upstream_preprocessing = FALSE,
    stringsAsFactors = FALSE
  )
}

#' Create a lightweight cross-package Gazepoint handoff
#'
#' @param data Prepared data frame.
#' @param source_package Upstream source package or `study_design`/`custom`.
#' @param source_version Optional source-package version.
#' @param producer Optional upstream function/workflow label.
#' @param keys Character vector of row-identifying join keys.
#' @param outcome Optional observed outcome column.
#' @param predictors Optional prepared predictor columns.
#' @param feature_manifest Optional gp3ml feature-provenance manifest.
#' @param notes Optional handoff notes.
#'
#' @return A `gp3ml_handoff` object.
#' @export
create_gazepoint_handoff <- function(
  data,
  source_package,
  source_version = NULL,
  producer = NULL,
  keys,
  outcome = NULL,
  predictors = character(),
  feature_manifest = NULL,
  notes = character()
) {
  .gp3ml_assert_data(data)

  source_package <- as.character(source_package[[1L]])
  if (!source_package %in% .gp3ml_interop_sources) {
    .gp3ml_stop(
      "`source_package` must be one of: %s.",
      paste(.gp3ml_interop_sources, collapse = ", ")
    )
  }

  keys <- unique(as.character(keys))
  predictors <- unique(as.character(predictors))
  .gp3ml_assert_columns(data, keys, "keys")
  if (length(predictors)) .gp3ml_assert_columns(data, predictors, "predictors")
  if (!is.null(outcome)) .gp3ml_assert_columns(data, outcome, "outcome")

  if (is.null(source_version) && source_package %in% c(
    "gp3tools", "gpbiometrics", "gp3sequences"
  )) {
    source_version <- tryCatch(
      as.character(utils::packageVersion(source_package)),
      error = function(e) NA_character_
    )
  }

  structure(
    list(
      source_package = source_package,
      source_version = source_version %||% NA_character_,
      producer = producer %||% NA_character_,
      keys = keys,
      outcome = outcome,
      predictors = predictors,
      feature_manifest = feature_manifest,
      data_hash = .gp3ml_hash_object(data),
      data = data,
      notes = as.character(notes)
    ),
    class = "gp3ml_handoff"
  )
}

.gp3ml_composite_key <- function(data, keys) {
  if (!length(keys)) return(rep("", nrow(data)))
  do.call(
    paste,
    c(
      lapply(data[keys], function(x) {
        value <- as.character(x)
        value[is.na(value)] <- "<NA>"
        value
      }),
      sep = "\r"
    )
  )
}

#' Validate a Gazepoint handoff
#'
#' @param x A `gp3ml_handoff`.
#'
#' @return A `gp3ml_handoff_validation` object.
#' @export
validate_gazepoint_handoff <- function(x) {
  if (!inherits(x, "gp3ml_handoff")) {
    .gp3ml_stop("`x` must be created by create_gazepoint_handoff().")
  }

  data_ok <- is.data.frame(x$data) && nrow(x$data) >= 2L
  keys_exist <- data_ok && length(x$keys) > 0L && all(x$keys %in% names(x$data))
  key_missing <- if (keys_exist) {
    any(vapply(x$data[x$keys], anyNA, logical(1)))
  } else {
    TRUE
  }
  duplicated_keys <- if (keys_exist) {
    anyDuplicated(.gp3ml_composite_key(x$data, x$keys)) > 0L
  } else {
    TRUE
  }
  predictors_exist <- all(x$predictors %in% names(x$data))
  outcome_exists <- is.null(x$outcome) || all(x$outcome %in% names(x$data))
  hash_matches <- data_ok && identical(x$data_hash, .gp3ml_hash_object(x$data))
  source_known <- x$source_package %in% .gp3ml_interop_sources

  checks <- data.frame(
    check = c(
      "supported_source",
      "tabular_data",
      "join_keys_present",
      "join_keys_complete",
      "join_keys_unique",
      "predictors_present",
      "outcome_present",
      "data_hash_matches"
    ),
    status = c(
      if (source_known) "pass" else "fail",
      if (data_ok) "pass" else "fail",
      if (keys_exist) "pass" else "fail",
      if (!key_missing) "pass" else "fail",
      if (!duplicated_keys) "pass" else "fail",
      if (predictors_exist) "pass" else "fail",
      if (outcome_exists) "pass" else "fail",
      if (hash_matches) "pass" else "fail"
    ),
    detail = c(
      x$source_package,
      if (data_ok) sprintf("%d rows x %d columns", nrow(x$data), ncol(x$data)) else "Invalid data frame.",
      paste(x$keys, collapse = ", "),
      if (!key_missing) "No missing join-key values." else "Missing join-key values detected.",
      if (!duplicated_keys) "Composite join key is unique." else "Duplicated composite join keys detected.",
      paste(x$predictors, collapse = ", "),
      x$outcome %||% "<none>",
      if (hash_matches) "Handoff data are unchanged." else "Handoff data differ from the recorded fingerprint."
    ),
    stringsAsFactors = FALSE
  )

  status <- if (any(checks$status == "fail")) "fail" else "pass"

  structure(
    list(
      status = status,
      checks = checks,
      source_package = x$source_package,
      data_hash = x$data_hash
    ),
    class = "gp3ml_handoff_validation"
  )
}

#' Combine validated cross-package handoffs
#'
#' @param handoffs Named list of `gp3ml_handoff` objects.
#' @param keys Optional join keys; defaults to the first handoff's keys.
#' @param collision How to handle overlapping non-key column names.
#'
#' @return A `gp3ml_handoff_bundle`.
#' @export
combine_gazepoint_handoffs <- function(
  handoffs,
  keys = NULL,
  collision = c("error", "prefix")
) {
  collision <- match.arg(collision)
  if (!is.list(handoffs) || length(handoffs) < 1L) {
    .gp3ml_stop("`handoffs` must be a non-empty list.")
  }
  if (is.null(names(handoffs)) || any(!nzchar(names(handoffs)))) {
    names(handoffs) <- paste0("source", seq_along(handoffs))
  }

  validations <- lapply(handoffs, validate_gazepoint_handoff)
  if (any(vapply(validations, function(x) x$status != "pass", logical(1)))) {
    .gp3ml_stop("Every handoff must pass validation before combination.")
  }

  keys <- keys %||% handoffs[[1L]]$keys
  keys <- unique(as.character(keys))
  for (x in handoffs) .gp3ml_assert_columns(x$data, keys, "keys")

  data_list <- lapply(seq_along(handoffs), function(i) {
    x <- handoffs[[i]]
    data <- x$data
    non_keys <- setdiff(names(data), keys)
    if (collision == "prefix") {
      names(data)[match(non_keys, names(data))] <- paste0(
        names(handoffs)[[i]], "__", non_keys
      )
    }
    data
  })

  if (collision == "error" && length(data_list) > 1L) {
    all_non_keys <- unlist(lapply(data_list, function(x) setdiff(names(x), keys)))
    duplicated <- unique(all_non_keys[duplicated(all_non_keys)])
    if (length(duplicated)) {
      .gp3ml_stop(
        "Non-key column collision across handoffs: %s. Use `collision = \"prefix\"` or resolve upstream.",
        paste(duplicated, collapse = ", ")
      )
    }
  }

  combined <- Reduce(
    function(x, y) merge(x, y, by = keys, all = FALSE, sort = FALSE),
    data_list
  )

  structure(
    list(
      data = combined,
      keys = keys,
      sources = vapply(handoffs, `[[`, character(1), "source_package"),
      handoffs = handoffs,
      validations = validations,
      data_hash = .gp3ml_hash_object(combined)
    ),
    class = "gp3ml_handoff_bundle"
  )
}

#' Extract model-ready data from a gp3ml handoff object
#'
#' @param x A `gp3ml_handoff` or `gp3ml_handoff_bundle`.
#' @param ... Reserved for future adapters.
#'
#' @return A data frame.
#' @export
as_gp3ml_data <- function(x, ...) {
  if (inherits(x, "gp3ml_handoff")) {
    validation <- validate_gazepoint_handoff(x)
    if (validation$status != "pass") {
      .gp3ml_stop("Handoff validation must pass before extracting data.")
    }
    return(x$data)
  }
  if (inherits(x, "gp3ml_handoff_bundle")) {
    return(x$data)
  }
  .gp3ml_stop("`x` must be a gp3ml handoff or handoff bundle.")
}

#' @method print gp3ml_handoff
#' @export
print.gp3ml_handoff <- function(x, ...) {
  cat(
    " gp3ml handoff from ", x$source_package,
    ": ", nrow(x$data), " rows, ",
    length(x$predictors), " predictors\n",
    sep = ""
  )
  invisible(x)
}

#' @method print gp3ml_handoff_validation
#' @export
print.gp3ml_handoff_validation <- function(x, ...) {
  cat(" gp3ml handoff validation: ", x$status, "\n", sep = "")
  print(x$checks, row.names = FALSE)
  invisible(x)
}

#' @method print gp3ml_handoff_bundle
#' @export
print.gp3ml_handoff_bundle <- function(x, ...) {
  cat(
    " gp3ml handoff bundle: ",
    length(x$handoffs),
    " sources, ",
    nrow(x$data),
    " joined rows\n",
    sep = ""
  )
  invisible(x)
}

#' Plot handoff validation checks
#'
#' @param x A `gp3ml_handoff_validation`.
#' @param ... Additional graphical parameters.
#'
#' @method plot gp3ml_handoff_validation
#' @export
plot.gp3ml_handoff_validation <- function(x, ...) {
  if (!inherits(x, "gp3ml_handoff_validation")) {
    .gp3ml_stop("`x` must be a gp3ml handoff validation.")
  }
  values <- table(factor(x$checks$status, levels = c("pass", "review", "fail")))
  graphics::barplot(
    values,
    ylab = "Checks",
    main = paste("Handoff validation:", x$status),
    ...
  )
  invisible(x)
}
