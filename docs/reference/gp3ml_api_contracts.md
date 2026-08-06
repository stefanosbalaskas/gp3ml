# gp3ml public API contracts

Returns the package's explicit compatibility contract for the public
API. APIs classified as stable in version 0.2.0 remain stable throughout
the 0.3.x line. New APIs introduced by the current development milestone
are marked experimental until promoted by a later release decision.

## Usage

``` r
gp3ml_api_contracts()
```

## Value

A `gp3ml_api_contract_registry` object.
