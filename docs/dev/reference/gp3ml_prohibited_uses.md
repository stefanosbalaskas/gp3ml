# Prohibited gp3ml uses

Prohibited gp3ml uses

## Usage

``` r
gp3ml_prohibited_uses()
```

## Value

A character vector of prohibited use descriptions.

## Examples

``` r
gp3ml_prohibited_uses()
#> [1] "person identification or re-identification"
#> [2] "biometric authentication or verification"
#> [3] "health, disease, disability, or diagnostic inference"
#> [4] "protected-attribute prediction or proxy prediction"
#> [5] "emotion, stress, personality, deception, cognition, comprehension, intent, or mental-state inference"
#> [6] "random row-level evaluation represented as participant- or stimulus-level generalization"
#> [7] "outcome-derived or post-outcome feature engineering"
#> [8] "preprocessing estimated using assessment or external-validation data"
#> [9] "accuracy-only reporting without discrimination, calibration, and uncertainty"
```
