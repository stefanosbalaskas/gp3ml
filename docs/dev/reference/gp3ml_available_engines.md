# List available model engines

List available model engines

## Usage

``` r
gp3ml_available_engines()
```

## Value

A data frame listing supported model-engine names and whether each
optional engine is currently available.

## Examples

``` r
gp3ml_available_engines()
#>    engine available
#> 1     glm      TRUE
#> 2      lm      TRUE
#> 3  ranger      TRUE
#> 4 xgboost      TRUE
#> 5    nnet      TRUE
#> 6  keras3     FALSE
#> 7  custom      TRUE
```
