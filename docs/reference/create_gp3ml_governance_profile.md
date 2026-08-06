# Create a governance-evidence profile

Create a governance-evidence profile

## Usage

``` r
create_gp3ml_governance_profile(
  evidence,
  framework = c("gp3ml-native", "NIST-AI-RMF-1.0", "ISO-23894-oriented",
    "ISO-42001-oriented")
)
```

## Arguments

- evidence:

  Named list of gp3ml evidence objects.

- framework:

  Governance crosswalk.

## Value

A `gp3ml_governance_profile`.
