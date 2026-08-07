# Rendered manuscript outputs

This directory is intentionally source-controlled without generated article files.

Run one of the following from the repository root:

```r
system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", "paper/R/render-paper.R", normalizePath(".", winslash = "/"))
)
```

or, for an HTML preview:

```r
system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", "paper/R/render-preview.R", normalizePath(".", winslash = "/"))
)
```

The render scripts install the current repository into a temporary library. They do not overwrite the user's installed `gp3ml` package.
