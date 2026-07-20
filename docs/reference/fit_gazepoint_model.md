# Fit a governed Gazepoint model

Fit a governed Gazepoint model

## Usage

``` r
fit_gazepoint_model(
  data,
  task,
  predictors = NULL,
  engine = NULL,
  preprocessor = NULL,
  preprocessor_args = list(),
  engine_args = list(),
  seed = 1L,
  threshold = 0.5
)
```

## Arguments

- data:

  Analysis data used to fit the model.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Optional character vector of predictor columns.

- engine:

  Engine name or controlled custom-engine object.

- preprocessor:

  Optional fitted preprocessing object.

- preprocessor_args:

  Arguments passed to preprocessing fitting.

- engine_args:

  Arguments passed to the model engine.

- seed:

  Deterministic random seed.

- threshold:

  Classification probability threshold.
