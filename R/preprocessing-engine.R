.gp3ml_prepare_raw_frame <- function(data, preprocessor = NULL, predictors = NULL, fit = FALSE, numeric_imputation = "median", novel_level = "other") {
  predictors <- predictors %||% preprocessor$predictors
  frame <- data[predictors]
  numeric_values <- list()
  factor_levels <- list()
  for (name in predictors) {
    x <- frame[[name]]
    if (is.logical(x)) x <- factor(x, levels = c(FALSE, TRUE))
    if (is.character(x)) x <- factor(x)
    if (is.numeric(x) || is.integer(x)) {
      if (fit) {
        value <- if (numeric_imputation == "mean") mean(x, na.rm = TRUE) else stats::median(x, na.rm = TRUE)
        if (!is.finite(value)) value <- 0
        numeric_values[[name]] <- value
      } else value <- preprocessor$numeric_imputation_values[[name]]
      x[is.na(x)] <- value
      frame[[name]] <- as.numeric(x)
    } else {
      x <- as.character(x)
      x[is.na(x) | !nzchar(x)] <- "<missing>"
      if (fit) {
        levels_found <- sort(unique(c(x, if (novel_level == "other") "<other>" else character())))
        factor_levels[[name]] <- levels_found
      } else {
        levels_found <- preprocessor$factor_levels[[name]]
        novel <- !x %in% levels_found
        if (any(novel) && preprocessor$novel_level == "error") .gp3ml_stop("Novel levels in `%s`.", name)
        x[novel] <- "<other>"
      }
      frame[[name]] <- factor(x, levels = levels_found)
    }
  }
  list(frame = frame, numeric_values = numeric_values, factor_levels = factor_levels)
}

#' Fit a fold-local preprocessing engine
#'
#' @param data Analysis data used to estimate preprocessing parameters.
#' @param predictors Character vector naming predictor columns.
#' @param numeric_imputation Numeric imputation method.
#' @param center Whether numeric model columns should be centered.
#' @param scale Whether numeric model columns should be scaled.
#' @param novel_level How novel categorical levels should be handled.
#' @param remove_zero_variance Whether zero-variance columns are removed.
#' @export
fit_gazepoint_preprocessor <- function(
    data,
    predictors,
    numeric_imputation = c("median", "mean"),
    center = TRUE,
    scale = TRUE,
    novel_level = c("other", "error"),
    remove_zero_variance = TRUE) {
  .gp3ml_assert_data(data)
  .gp3ml_assert_columns(data, predictors, "predictors")
  numeric_imputation <- match.arg(numeric_imputation)
  novel_level <- match.arg(novel_level)
  prepared <- .gp3ml_prepare_raw_frame(data, predictors = predictors, fit = TRUE, numeric_imputation = numeric_imputation, novel_level = novel_level)
  matrix <- stats::model.matrix(~ . - 1, data = prepared$frame, na.action = stats::na.pass)
  if (!is.matrix(matrix)) matrix <- as.matrix(matrix)
  keep <- rep(TRUE, ncol(matrix))
  if (isTRUE(remove_zero_variance) && ncol(matrix)) {
    keep <- vapply(seq_len(ncol(matrix)), function(i) length(unique(matrix[, i])) > 1L, logical(1))
  }
  matrix <- matrix[, keep, drop = FALSE]
  means <- if (isTRUE(center) && ncol(matrix)) colMeans(matrix) else rep(0, ncol(matrix))
  sds <- if (isTRUE(scale) && ncol(matrix)) apply(matrix, 2L, stats::sd) else rep(1, ncol(matrix))
  sds[!is.finite(sds) | sds == 0] <- 1
  structure(
    list(
      predictors = predictors,
      numeric_imputation = numeric_imputation,
      numeric_imputation_values = prepared$numeric_values,
      factor_levels = prepared$factor_levels,
      novel_level = novel_level,
      columns = colnames(matrix),
      center = means,
      scale = sds,
      remove_zero_variance = remove_zero_variance
    ),
    class = "gp3ml_preprocessor"
  )
}

#' Apply a fitted preprocessing engine
#'
#' @param preprocessor A fitted `gp3ml_preprocessor` object.
#' @param new_data Data to transform using the fitted parameters.
#' @export
bake_gazepoint_preprocessor <- function(preprocessor, new_data) {
  if (!inherits(preprocessor, "gp3ml_preprocessor")) .gp3ml_stop("`preprocessor` must be fitted by gp3ml.")
  .gp3ml_assert_columns(new_data, preprocessor$predictors, "predictors")
  prepared <- .gp3ml_prepare_raw_frame(new_data, preprocessor = preprocessor, fit = FALSE)
  matrix <- stats::model.matrix(~ . - 1, data = prepared$frame, na.action = stats::na.pass)
  missing <- setdiff(preprocessor$columns, colnames(matrix))
  for (name in missing) matrix <- cbind(matrix, stats::setNames(rep(0, nrow(matrix)), name))
  matrix <- matrix[, preprocessor$columns, drop = FALSE]
  matrix <- sweep(matrix, 2L, preprocessor$center, "-")
  matrix <- sweep(matrix, 2L, preprocessor$scale, "/")
  storage.mode(matrix) <- "double"
  matrix
}

#' @method print gp3ml_preprocessor
#' @export
print.gp3ml_preprocessor <- function(x, ...) {
  cat("<gp3ml_preprocessor> ", length(x$predictors), " raw predictors -> ", length(x$columns), " model columns\n", sep = "")
  invisible(x)
}
