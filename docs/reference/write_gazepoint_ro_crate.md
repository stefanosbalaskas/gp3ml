# Write a minimal RO-Crate-oriented research object

This helper writes a conservative RO-Crate-oriented JSON-LD metadata
file and SHA-256 file hashes. It does not claim formal RO-Crate
conformance; use an independent validator when formal conformance is
required.

## Usage

``` r
write_gazepoint_ro_crate(
  path,
  files,
  name,
  description,
  creator_name,
  creator_orcid = NULL,
  license = "MIT",
  doi = NULL,
  copy_files = TRUE
)
```

## Arguments

- path:

  Output directory.

- files:

  Named or unnamed character vector of files to include.

- name:

  Research-object name.

- description:

  Description.

- creator_name:

  Creator name.

- creator_orcid:

  Optional ORCID URI or identifier.

- license:

  License URI or label.

- doi:

  Optional DOI.

- copy_files:

  Whether to copy files into the crate directory.

## Value

A `gp3ml_ro_crate`.
