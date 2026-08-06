# Combine validated cross-package handoffs

Combine validated cross-package handoffs

## Usage

``` r
combine_gazepoint_handoffs(
  handoffs,
  keys = NULL,
  collision = c("error", "prefix")
)
```

## Arguments

- handoffs:

  Named list of `gp3ml_handoff` objects.

- keys:

  Optional join keys; defaults to the first handoff's keys.

- collision:

  How to handle overlapping non-key column names.

## Value

A `gp3ml_handoff_bundle`.
