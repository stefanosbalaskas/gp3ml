# Test model-artifact serialization and optional fresh-process prediction

Test model-artifact serialization and optional fresh-process prediction

## Usage

``` r
test_gazepoint_model_portability(
  artifact,
  newdata = artifact$reference_data,
  tolerance = 1e-08,
  fresh_process = FALSE
)
```

## Arguments

- artifact:

  Model artifact.

- newdata:

  Optional prediction fixture.

- tolerance:

  Numeric prediction tolerance.

- fresh_process:

  Whether to test in a fresh R process using `callr`.

## Value

A `gp3ml_model_portability_test`.
