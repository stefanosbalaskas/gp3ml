# Cross-package interoperability contracts

Describes a lightweight handoff boundary. Upstream packages remain
responsible for their own importing, cleaning, feature derivation,
signal processing, sequence processing, and quality control. `gp3ml`
receives already prepared observed variables together with explicit
provenance.

## Usage

``` r
gp3ml_interop_contracts()
```

## Value

A data frame describing supported handoff sources and responsibilities.
