## Submission

This is an update to the CRAN package gp3ml from version 0.1.0 to
version 0.3.0.

Version 0.2.0 was published as a GitHub and Zenodo source release but
was not submitted to CRAN; therefore the CRAN version moves directly
from 0.1.0 to 0.3.0.

Version 0.3.0 adds repository-aware grouped-fold evaluation, explicit
governed tuning, nested grouped resampling, target-aligned uncertainty,
external-validation and transportability reporting, explicit API
contracts, cross-package handoffs, prediction-to-decision governance,
target-aware conformal prediction, dataset-shift auditing, locked
analysis plans, portable model artifacts, robustness diagnostics,
environment provenance, research-object export, and release-evidence
profiles.

The package remains restricted to explicitly observed, non-sensitive
outcomes and declared scientific purposes. It does not support person
identification or authentication, health or protected-attribute
inference, or direct or indirect inference of emotion, stress,
personality, deception, cognition, comprehension, intent, or other
mental states.

## Test environments

* Local Windows 11 x64 (build 26200), R 4.6.1 (2026-06-24 ucrt)
* Direct `R CMD check --as-cran --run-donttest` of the exact
  `gp3ml_0.3.0.tar.gz` source archive
* All declared Suggests packages installed and available during the
  complete archive check

## R CMD check results

0 errors | 0 warnings | 0 notes

The complete testthat suite passed. All examples and vignettes were
checked and rebuilt successfully. The package contains 20 source vignettes.

## Reverse dependencies

There are currently no CRAN reverse dependencies, including packages
that list gp3ml in Suggests.

## Additional notes

* Tests, examples, and vignettes use deterministic synthetic,
  non-sensitive data; no private participant data are included.
* Optional engines are checked conditionally and report unavailable
  dependencies or runtimes explicitly rather than failing package-core
  workflows.
* The Zenodo concept DOI is `10.5281/zenodo.21487272`.
* The version-specific DOI for gp3ml 0.3.0 will be added after the
  release is archived.
