# Create a release evidence manifest

Create a release evidence manifest

## Usage

``` r
create_gazepoint_release_evidence(
  objects = list(),
  files = character(),
  version = "0.2.0",
  notes = character()
)

# S3 method for class 'gp3ml_release_evidence'
print(x, ...)
```

## Arguments

- objects:

  Named analysis objects to fingerprint.

- files:

  Named file paths to checksum.

- version:

  Intended future release version.

- notes:

  Optional release notes.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_release_evidence` object.
