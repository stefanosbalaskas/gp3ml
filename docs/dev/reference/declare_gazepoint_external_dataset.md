# Declare an external dataset and its independence status

Declare an external dataset and its independence status

## Usage

``` r
declare_gazepoint_external_dataset(
  data,
  label,
  independent,
  origin,
  collection_period = NULL,
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  notes = character()
)

# S3 method for class 'gp3ml_external_dataset_declaration'
print(x, ...)
```

## Arguments

- data:

  Candidate external-validation data.

- label:

  Dataset label.

- independent:

  Explicit logical declaration of independence from model development
  and internal resampling.

- origin:

  Human-readable origin or collection source.

- collection_period:

  Optional collection period.

- participant_id:

  Participant identifier column.

- stimulus_id:

  Stimulus identifier column.

- notes:

  Optional notes.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_external_dataset_declaration`.

## Examples

``` r
external <- simulate_gazepoint_governed_data(8L, 4L, 1L, 505L)
declaration <- declare_gazepoint_external_dataset(
  external,
  label = "synthetic_external_site",
  independent = TRUE,
  origin = "Independent deterministic synthetic site"
)
declaration
#> <gp3ml_external_dataset_declaration>
#>   Label: synthetic_external_site
#>   Independent: TRUE
#>   Origin: Independent deterministic synthetic site
#>   Rows: 32
```
