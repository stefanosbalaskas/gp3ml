required <- c(
  "rmarkdown", "knitr", "rjtools", "openssl", "devtools", "pkgdown",
  "testthat", "jsonlite", "callr"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
optional <- c("bundle", "hunspell")
optional_missing <- optional[!vapply(optional, requireNamespace, logical(1), quietly = TRUE)]
if (length(optional_missing)) {
  message(
    "Optional manuscript capabilities are unavailable until installed: ",
    paste(optional_missing, collapse = ", ")
  )
}
cat("Core manuscript dependencies are available.\n")
