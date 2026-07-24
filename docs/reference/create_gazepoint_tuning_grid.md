# Create an explicit governed tuning grid

Candidate values are fully materialized before evaluation. No hidden
metric, default ranking rule, or automatic winner is created.

## Usage

``` r
create_gazepoint_tuning_grid(
  engine,
  engine_grid = list(),
  preprocessor_grid = list(),
  thresholds = 0.5,
  complexity = NA,
  interpretability = NA,
  labels = NULL
)

# S3 method for class 'gp3ml_tuning_grid'
print(x, ...)
```

## Arguments

- engine:

  One or more governed engine names.

- engine_grid:

  Named list of engine-argument candidate values.

- preprocessor_grid:

  Named list of preprocessing-argument candidate values.

- thresholds:

  One or more explicit classification thresholds.

- complexity:

  Optional complexity labels or numeric scores.

- interpretability:

  Optional interpretability labels or numeric scores.

- labels:

  Optional candidate labels.

- x:

  An object returned by the corresponding gp3ml constructor, evaluator,
  summarizer, or validator.

- ...:

  Additional arguments passed to the print method.

## Value

A `gp3ml_tuning_grid` with one row per explicit candidate.

## Examples

``` r
grid <- create_gazepoint_tuning_grid(
  engine = "glm",
  preprocessor_grid = list(center = c(TRUE, FALSE), scale = TRUE),
  thresholds = c(0.4, 0.5),
  complexity = "low",
  interpretability = "high"
)
grid
#> <gp3ml_tuning_grid> candidates=4
#>   candidate_id
#>  candidate_001
#>  candidate_002
#>  candidate_003
#>  candidate_004
#>                                                              label engine
#>   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.4]    glm
#>  glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.4]    glm
#>   glm [engine:default; prep:center=TRUE,scale=TRUE; threshold=0.5]    glm
#>  glm [engine:default; prep:center=FALSE,scale=TRUE; threshold=0.5]    glm
#>  threshold complexity interpretability
#>        0.4        low             high
#>        0.4        low             high
#>        0.5        low             high
#>        0.5        low             high
```
