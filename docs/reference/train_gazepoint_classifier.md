# Generic governed binary-classifier training wrapper

Generic governed binary-classifier training wrapper

## Usage

``` r
train_gazepoint_classifier(data, task, predictors = NULL, engine = "glm", ...)
```

## Arguments

- data:

  Analysis data used to train the classifier.

- task:

  A governed binary-classification task.

- predictors:

  Optional character vector of predictor columns.

- engine:

  Classification engine name or custom engine.

- ...:

  Additional arguments passed to
  [`fit_gazepoint_model()`](https://stefanosbalaskas.github.io/gp3ml/reference/fit_gazepoint_model.md).
