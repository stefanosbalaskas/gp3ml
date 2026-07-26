# Optional Engines and Cross-Platform Portability

## Capability table

Optional engines remain optional. Missing packages are reported
explicitly rather than changing the scientific task or silently
selecting another model.

``` r

capabilities <- gp3ml_engine_capabilities(
  check_keras_backend = FALSE
)
capabilities
#>   engine package classification regression probability package_available
#>      glm    <NA>           TRUE      FALSE        TRUE              TRUE
#>       lm    <NA>          FALSE       TRUE       FALSE              TRUE
#>   ranger  ranger           TRUE       TRUE        TRUE              TRUE
#>  xgboost xgboost           TRUE       TRUE        TRUE              TRUE
#>     nnet    nnet           TRUE       TRUE        TRUE              TRUE
#>   keras3  keras3           TRUE       TRUE        TRUE             FALSE
#>   custom    <NA>           TRUE       TRUE          NA              TRUE
#>  backend backend_ready      status
#>     <NA>            NA   available
#>     <NA>            NA   available
#>     <NA>            NA   available
#>     <NA>            NA   available
#>     <NA>            NA   available
#>     <NA>            NA unavailable
#>     <NA>            NA   available
#>                                                                      notes
#>                                                       Base-R binomial GLM.
#>                                                       Base-R linear model.
#>                                        Optional package; governed wrapper.
#>                                        Optional package; governed wrapper.
#>                                   Recommended R package; governed wrapper.
#>  Optional package plus configured backend; deep learning remains explicit.
#>                   Externally supplied engine requires safety declarations.
plot(capabilities)
```

![](optional-engine-portability_files/figure-html/capabilities-1.png)

`glm` and `lm` are always available. `ranger`, `xgboost`, `nnet`, and
`keras3` are exercised by a dedicated GitHub Actions matrix. Keras
backend readiness is queried only when explicitly requested.

``` r

assert_gp3ml_engine_available("glm")
assert_gp3ml_engine_available("lm")
```

Engine availability is not a model-selection rule. Candidate selection
remains explicit, metric-declared, direction-declared, and reviewable.
