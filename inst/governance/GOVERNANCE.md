# gp3ml Model Governance

## Purpose

`gp3ml` is intended to provide leakage-resistant, group-aware,
auditable predictive-validation infrastructure for explicitly
labelled, non-sensitive outcomes in Gazepoint research workflows.

The package is not intended to serve as a generic machine-learning
training wrapper.

## Required generalization target

Every predictive evaluation must declare one of the following:

- new trials from known participants;
- new participants;
- new stimuli; or
- new participants and new stimuli.

The data split and resampling structure must be compatible with the
declared target.

## Core safeguards

- Participant leakage must be prevented by default.
- Stimulus leakage must be prevented when unseen-stimulus
  generalization is claimed.
- Random row-level splitting is not the default.
- Preprocessing must be estimated inside resampling folds.
- Outcome-derived feature selection is prohibited.
- Identifiers must not be used as predictors.
- Evaluation must not rely on accuracy alone.
- Calibration and uncertainty must be reported when applicable.
- Synthetic data used in examples and tests must be deterministic.

## Initial model scope

The initial package will not provide broad model-training wrappers.
Transparent baseline models may be considered only after leakage
auditing, grouped resampling, evaluation, and reporting safeguards
are complete and validated.
