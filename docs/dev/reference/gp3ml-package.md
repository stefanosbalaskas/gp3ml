# gp3ml: Governance-First Predictive Modelling for 'Gazepoint' Research

`gp3ml` provides governance-first infrastructure for leakage-resistant
predictive modelling and validation using Gazepoint-derived research
data.

## Details

Core capabilities include explicit task and variable-role declarations,
feature-provenance manifests, leakage auditing, group-aware holdout
splitting and repeated resampling, fold-local preprocessing, governed
model engines, performance and calibration assessment, uncertainty,
external- validation reports, model cards, and reproducibility reports.

## Repository-aware evaluation and tuning

Materialized `gazepoint_group_folds` can be evaluated without rebuilding
or replacing the fold object. Preprocessing and model fitting occur only
within each analysis partition; predictions are produced only for the
matching assessment partition. Explicit candidate grids retain failed
candidates and require a declared metric, direction, and human rationale
before selection.

## Nested resampling and uncertainty

Nested grouped resampling isolates inner tuning inside each outer
analysis partition. Target-aligned uncertainty distinguishes
observation, participant-cluster, stimulus-cluster, simultaneous
participant/stimulus, fold-distribution, and repeat-distribution
summaries. An uncertainty object may not be described as uncertainty for
an undeclared unit.

## External validation

External validation requires an explicit independent-dataset
declaration. Reports include predictor availability, schema differences,
prevalence shift, calibration drift, participant/stimulus coverage, and
transportability limitations. Internal holdouts remain explicitly
labelled as not externally validated.

The package is intended only for explicitly observed, non-sensitive
outcomes and declared scientific purposes. It does not support person
identification, biometric authentication, health or protected-attribute
inference, or direct or indirect inference of emotion, stress,
personality, deception, cognition, comprehension, intent, or other
mental states.

## See also

Useful links:

- <https://stefanosbalaskas.github.io/gp3ml/>

- <https://github.com/stefanosbalaskas/gp3ml>

- Report bugs at <https://github.com/stefanosbalaskas/gp3ml/issues>

## Author

**Maintainer**: Stefanos Balaskas <s.balaskas@ac.upatras.gr>
([ORCID](https://orcid.org/0000-0003-2444-9796))

Authors:

- Stefanos Balaskas <s.balaskas@ac.upatras.gr>
  ([ORCID](https://orcid.org/0000-0003-2444-9796))
