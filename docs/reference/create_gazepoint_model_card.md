# Create a governance-focused model card

Create a governance-focused model card

## Usage

``` r
create_gazepoint_model_card(
  model,
  intended_use,
  evaluation = NULL,
  calibration = NULL,
  feature_manifest = NULL,
  external_validation = NULL,
  limitations = character(),
  ethical_review = NULL
)
```

## Arguments

- model:

  A fitted `gp3ml_model` object.

- intended_use:

  Explicit description of the intended research use.

- evaluation:

  Optional performance-evaluation object.

- calibration:

  Optional calibration-assessment object.

- feature_manifest:

  Optional feature-provenance manifest.

- external_validation:

  Optional external-validation result.

- limitations:

  Character vector describing model limitations.

- ethical_review:

  Optional ethical-review information.
