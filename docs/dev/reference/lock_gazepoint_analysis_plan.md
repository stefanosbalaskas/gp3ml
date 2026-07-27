# Lock an analysis plan using SHA-256

Lock an analysis plan using SHA-256

## Usage

``` r
lock_gazepoint_analysis_plan(plan, plan_id = NULL, locked_at = Sys.time())
```

## Arguments

- plan:

  A valid unlocked plan.

- plan_id:

  Optional stable identifier.

- locked_at:

  Optional lock time.

## Value

A locked `gp3ml_analysis_plan`.
