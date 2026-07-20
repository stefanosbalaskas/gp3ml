# Validate outcome, predictor, identifier, and grouping roles

Validate outcome, predictor, identifier, and grouping roles

## Usage

``` r
validate_gazepoint_ml_roles(data, task, predictors, feature_manifest = NULL)
```

## Arguments

- data:

  A data frame containing outcome, predictors, and identifiers.

- task:

  A governed `gp3ml_task` object.

- predictors:

  Character vector naming intended predictors.

- feature_manifest:

  Optional Gazepoint feature-provenance manifest.
