# Simulate realistic cross-package Gazepoint research handoffs

Generates deterministic, shareable, synthetic prepared outputs
representing handoffs from `gp3tools`, `gpbiometrics`, and
`gp3sequences`. The outcome is an experimentally assigned condition.
Biometrics variables are signal-quality summaries only; no health,
emotion, stress, cognition, or other mental-state outcome is generated
or inferred.

## Usage

``` r
simulate_gazepoint_research_handoffs(
  n_participants = 24L,
  n_stimuli = 6L,
  trials_per_stimulus = 1L,
  seed = 3001L
)
```

## Arguments

- n_participants:

  Number of participants.

- n_stimuli:

  Number of stimuli.

- trials_per_stimulus:

  Trials per participant-stimulus cell.

- seed:

  Deterministic seed.

## Value

A `gp3ml_research_bundle`.
