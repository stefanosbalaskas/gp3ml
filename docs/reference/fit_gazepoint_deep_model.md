# Fit an optional governed deep-learning model through keras3

Fit an optional governed deep-learning model through keras3

## Usage

``` r
fit_gazepoint_deep_model(
  data,
  task,
  predictors = NULL,
  preprocessor = NULL,
  hidden_units = c(64L, 32L),
  dropout = 0.2,
  epochs = 50L,
  batch_size = 32L,
  validation_split = 0.2,
  optimizer = "adam",
  seed = 1L,
  verbose = 0L
)
```

## Arguments

- data:

  Analysis data used to fit the network.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Optional character vector of predictor columns.

- preprocessor:

  Optional fitted preprocessing object.

- hidden_units:

  Integer vector of hidden-layer sizes.

- dropout:

  Dropout proportion applied after hidden layers.

- epochs:

  Number of training epochs.

- batch_size:

  Training batch size.

- validation_split:

  Proportion reserved for internal validation.

- optimizer:

  Keras optimizer name or object.

- seed:

  Deterministic random seed.

- verbose:

  Keras training verbosity.
