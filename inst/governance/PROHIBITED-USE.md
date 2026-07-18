# gp3ml Prohibited Uses

`gp3ml` must not be used to build or support:

- person identification or re-identification;
- biometric authentication;
- protected-attribute prediction;
- health, clinical, or diagnostic inference;
- emotion recognition;
- stress or mental-state inference;
- cognition or comprehension inference;
- personality prediction;
- deception detection;
- intent inference;
- sensitive-attribute prediction;
- surveillance or behavioral profiling;
- high-impact decisions about employment, education, insurance,
  healthcare, credit, law enforcement, or legal status.

Gaze, pupil, and biometric signals must not be presented as direct
measurements of any of these constructs.

The package must also not support predictive claims based on
participant leakage, stimulus leakage, target-derived predictors,
global preprocessing before resampling, or evaluation on a reused
final test set.
