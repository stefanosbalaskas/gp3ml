# Audit generated artifacts for volatile output

Audit generated artifacts for volatile output

## Usage

``` r
audit_gazepoint_reproducibility(
  paths,
  recursive = TRUE,
  extensions = c("R", "Rmd", "Rd", "md", "txt", "html", "json", "csv", "yml", "yaml")
)
```

## Arguments

- paths:

  Files or directories to audit.

- recursive:

  Whether directories are searched recursively.

- extensions:

  Text-file extensions to inspect.

## Value

A `gp3ml_reproducibility_audit`.
