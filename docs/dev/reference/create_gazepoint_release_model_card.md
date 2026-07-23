# Create a release-ready governed model card

Extends the existing model-card structure with explicit model-selection,
target-aligned uncertainty, nested-resampling, and transportability
fields.

## Usage

``` r
create_gazepoint_release_model_card(
  model,
  intended_use,
  evaluation = NULL,
  selection = NULL,
  uncertainty = NULL,
  calibration = NULL,
  feature_manifest = NULL,
  transportability = NULL,
  limitations,
  ethical_review = NULL,
  deployment_status = "research_review_only"
)

# S3 method for class 'gp3ml_release_model_card'
print(x, ...)
```

## Arguments

- model:

  Fitted governed model.

- intended_use:

  Intended scientific use.

- evaluation:

  Grouped or nested evaluation.

- selection:

  Optional `gp3ml_model_selection`.

- uncertainty:

  Optional target-aligned uncertainty object.

- calibration:

  Optional calibration assessment.

- feature_manifest:

  Optional feature manifest.

- transportability:

  Optional transportability report.

- limitations:

  Required limitations.

- ethical_review:

  Optional ethical-review information.

- deployment_status:

  Deployment status; defaults to research review only.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_release_model_card`.
