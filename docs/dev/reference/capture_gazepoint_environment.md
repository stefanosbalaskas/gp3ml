# Capture a reproducibility environment record

Capture a reproducibility environment record

## Usage

``` r
capture_gazepoint_environment(
  packages = unique(c("gp3ml", loadedNamespaces())),
  root = ".",
  include_renv = FALSE
)
```

## Arguments

- packages:

  Packages to record. Defaults to gp3ml and currently loaded namespaces.

- root:

  Repository/project root used to capture Git SHA.

- include_renv:

  Whether to record an existing `renv.lock` hash.

## Value

A `gp3ml_environment_record`.
