
.gp3ml_optional_engine_packages <- c(
  ranger = "ranger",
  xgboost = "xgboost",
  nnet = "nnet",
  keras3 = "keras3"
)

#' Audit gp3ml model-engine capabilities
#'
#' @param check_keras_backend Whether to query the configured Keras backend.
#'
#' @return A `gp3ml_engine_capabilities` data frame.
#' @export
gp3ml_engine_capabilities <- function(check_keras_backend = FALSE) {
  engines <- c("glm", "lm", "ranger", "xgboost", "nnet", "keras3", "custom")

  package <- c(
    NA_character_,
    NA_character_,
    "ranger",
    "xgboost",
    "nnet",
    "keras3",
    NA_character_
  )

  package_available <- vapply(package, function(pkg) {
    if (is.na(pkg)) return(TRUE)
    requireNamespace(pkg, quietly = TRUE)
  }, logical(1))

  backend <- rep(NA_character_, length(engines))
  backend_ready <- rep(NA, length(engines))

  keras_row <- which(engines == "keras3")
  if (package_available[[keras_row]] && isTRUE(check_keras_backend)) {
    value <- tryCatch(
      keras3::config_backend(),
      error = function(e) NA_character_
    )
    backend[[keras_row]] <- value
    backend_ready[[keras_row]] <- !is.na(value) && nzchar(value)
  }

  status <- ifelse(package_available, "available", "unavailable")
  if (package_available[[keras_row]] && !isTRUE(check_keras_backend)) {
    status[[keras_row]] <- "backend_unverified"
  } else if (package_available[[keras_row]] && isTRUE(check_keras_backend)) {
    status[[keras_row]] <- if (isTRUE(backend_ready[[keras_row]])) {
      "available"
    } else {
      "backend_unavailable"
    }
  }

  result <- data.frame(
    engine = engines,
    package = package,
    classification = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE),
    regression = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    probability = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, NA),
    package_available = package_available,
    backend = backend,
    backend_ready = backend_ready,
    status = status,
    notes = c(
      "Base-R binomial GLM.",
      "Base-R linear model.",
      "Optional package; governed wrapper.",
      "Optional package; governed wrapper.",
      "Recommended R package; governed wrapper.",
      "Optional package plus configured backend; deep learning remains explicit.",
      "Externally supplied engine requires safety declarations."
    ),
    stringsAsFactors = FALSE
  )

  class(result) <- c("gp3ml_engine_capabilities", class(result))
  result
}

#' Assert that a gp3ml engine is available
#'
#' @param engine Engine name.
#' @param check_keras_backend Whether to verify a configured Keras backend.
#'
#' @return Invisibly `TRUE` on success.
#' @export
assert_gp3ml_engine_available <- function(
  engine,
  check_keras_backend = FALSE
) {
  engine <- as.character(engine[[1L]])
  table <- gp3ml_engine_capabilities(
    check_keras_backend = check_keras_backend
  )

  row <- table[table$engine == engine, , drop = FALSE]
  if (!nrow(row)) .gp3ml_stop("Unknown gp3ml engine `%s`.", engine)

  if (!isTRUE(row$package_available[[1L]])) {
    .gp3ml_stop(
      "Engine `%s` requires optional package `%s`, which is not installed.",
      engine,
      row$package[[1L]]
    )
  }

  if (
    identical(engine, "keras3") &&
      isTRUE(check_keras_backend) &&
      !isTRUE(row$backend_ready[[1L]])
  ) {
    .gp3ml_stop(
      "`keras3` is installed but a usable backend was not confirmed. Configure a supported Keras backend before fitting."
    )
  }

  invisible(TRUE)
}

#' @method print gp3ml_engine_capabilities
#' @export
print.gp3ml_engine_capabilities <- function(x, ...) {
  NextMethod("print", x, row.names = FALSE, ...)
  invisible(x)
}

#' Plot gp3ml engine availability
#'
#' @param x Engine-capability table.
#' @param ... Additional graphical parameters.
#'
#' @method plot gp3ml_engine_capabilities
#' @export
plot.gp3ml_engine_capabilities <- function(x, ...) {
  if (!inherits(x, "gp3ml_engine_capabilities")) {
    .gp3ml_stop("`x` must be created by gp3ml_engine_capabilities().")
  }
  values <- as.integer(x$package_available)
  names(values) <- x$engine
  graphics::barplot(
    values,
    ylim = c(0, 1),
    yaxt = "n",
    ylab = "Package available",
    main = "gp3ml engine portability",
    ...
  )
  graphics::axis(2, at = c(0, 1), labels = c("no", "yes"))
  invisible(x)
}
