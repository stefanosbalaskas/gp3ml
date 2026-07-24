# Write a release-ready governed model card

Write a release-ready governed model card

## Usage

``` r
write_gazepoint_release_model_card(
  card,
  path,
  format = c("markdown", "json"),
  overwrite = FALSE
)
```

## Arguments

- card:

  A `gp3ml_release_model_card`.

- path:

  Destination path.

- format:

  Markdown or JSON.

- overwrite:

  Whether an existing file may be replaced.

## Value

The destination path, invisibly.
