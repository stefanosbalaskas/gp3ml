# Ecosystem update — September 2026

## Related hierarchical modelling addition

The related Python package **gpbiometricspy** now includes a fully
exact-main-certified crossed participant–item Gaussian hierarchical
location–scale model with **one location random slope for each crossed
factor**.

This is a complementary modelling path rather than an addition to
`gp3ml`. `gp3ml` remains focused on governed predictive modelling and
its own frozen API/release evidence. The gpbiometricspy method instead
targets repeated continuous outcomes with crossed participant/item
heterogeneity in both location and residual scale, plus factor-specific
location slopes.

Certified gpbiometricspy PR \#129 is pinned to merge SHA
`d078e0366ace49c3ebeb2f6800bad6394d70631e`: 14/14 exact-main push
workflow families, 12/12 OS/Python matrix lanes, 782/782 tests,
14,015/14,015 statements, and 6,757/6,776 raw branches (99.7196%). The
frozen `gpbiometrics 2.0.0` parity surface remains 406/406 and is not
altered by the new Python-native method.

- [Crossed participant–item random-slope
  guide](https://stefanosbalaskas.github.io/gpbiometricspy/methods/crossed-random-slopes-location-scale/)
- [gpbiometricspy PR
  \#129](https://github.com/stefanosbalaskas/gpbiometricspy/pull/129)

The two packages therefore remain methodologically distinct: use `gp3ml`
when the scientific claim is predictive and its
validation/generalization contract is primary; use the gpbiometricspy
location–scale family when the target is explicitly modelled conditional
distributional heterogeneity under the stated assumptions.
