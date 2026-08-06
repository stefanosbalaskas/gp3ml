# Create a portable governed model artifact

Create a portable governed model artifact

## Usage

``` r
create_gazepoint_model_artifact(
  model,
  preprocessor = model$preprocessor %||% NULL,
  feature_manifest = NULL,
  task = model$task %||% NULL,
  decision_rule = NULL,
  model_card = NULL,
  reference_data = NULL,
  bundle_model = TRUE
)
```

## Arguments

- model:

  A fitted `gp3ml_model` or controlled model object.

- preprocessor:

  Optional preprocessing object.

- feature_manifest:

  Optional feature manifest.

- task:

  Optional task; defaults to `model$task`.

- decision_rule:

  Optional decision rule.

- model_card:

  Optional model card.

- reference_data:

  Optional deterministic prediction fixture.

- bundle_model:

  Whether to attempt
  [`bundle::bundle()`](https://rstudio.github.io/bundle/reference/bundle.html)
  when available.

## Value

A `gp3ml_model_artifact`.
