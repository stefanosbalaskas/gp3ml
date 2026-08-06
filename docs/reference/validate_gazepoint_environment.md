# Validate the current environment against a reference record

Validate the current environment against a reference record

## Usage

``` r
validate_gazepoint_environment(reference, root = ".", include_renv = FALSE)
```

## Arguments

- reference:

  Reference environment record.

- root:

  Project root.

- include_renv:

  Whether to compare renv lock hashes.

## Value

An environment comparison.
