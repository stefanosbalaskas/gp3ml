## Submission

This is a new package submission for gp3ml 0.2.0.

gp3ml provides governance-first machine-learning workflows for repeated-measures Gazepoint research. Version 0.2.0 adds governed model tuning, nested grouped resampling, resample evaluation, target uncertainty, external transportability assessment, synthetic governed workflows, and release-evidence and model-card reporting.

The package is restricted to non-sensitive observed recording-quality and behavioural endpoints. It does not support identity or authentication, health or protected-attribute inference, or emotion, stress, personality, deception, cognition, comprehension, intent, or other mental-state inference.

## Test environments

* Local Windows 11 x64 (build 26200), R 4.6.1 (2026-06-24 ucrt)
* `R CMD check --as-cran --run-donttest`

## R CMD check results

0 errors | 0 warnings | 0 notes

All suggested packages were available for the check. `keras3` 1.5.1 and its missing R dependencies were installed only in an isolated temporary library.

The complete testthat suite passed before the check. All nine vignettes built, checked, and rebuilt successfully.

## Additional notes

* Tests, examples, and vignettes use deterministic synthetic non-sensitive data; no private participant data are included.

* Zenodo archival identifiers: concept DOI `10.5281/zenodo.21487272`; version-specific DOI for gp3ml 0.2.0 `10.5281/zenodo.21532057`.
