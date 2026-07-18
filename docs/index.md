# gp3ml

`gp3ml` is an R package under cautious development for leakage-resistant
and group-aware predictive validation using Gazepoint-derived research
data.

## Scope

The first development stages focus on:

- participant-, trial-, and stimulus-leakage auditing;
- explicit generalization-target declarations;
- outcome, predictor, and identifier-role validation;
- feature-provenance manifests;
- grouped train/test splitting;
- grouped and nested resampling plans;
- fold-overlap and balance diagnostics;
- calibration and uncertainty assessment;
- model-card and reproducibility reporting.

The package is not intended to be a generic wrapper around existing
machine-learning frameworks.

## Scientific safeguards

Participant leakage is prevented by default. Stimulus grouping is
required when the intended target is generalization to unseen stimuli.
Preprocessing and feature selection must be estimated inside the
relevant resampling folds.

All package examples and tests will use deterministic synthetic data.

## Prohibited uses

The package does not support person identification, health inference,
protected-attribute prediction, or direct inference of emotion, stress,
mental state, cognition, comprehension, personality, deception, or
intent.

See:

- [`GOVERNANCE.md`](https://stefanosbalaskas.github.io/gp3ml/inst/governance/GOVERNANCE.md)
- [`PROHIBITED-USE.md`](https://stefanosbalaskas.github.io/gp3ml/inst/governance/PROHIBITED-USE.md)

## Development status

Version `0.0.0.9000` is the initial governance-only bootstrap. No
model-training interface has been implemented.
