# API Stability and Public Object Contracts

## Why an explicit contract layer?

`gp3ml` distinguishes the public API established by version 0.2.0 from
new development APIs. Stable exported names and registered public S3
classes should not silently disappear or change meaning within the 0.2.x
line.

``` r

registry <- gp3ml_api_contracts()
registry
#>  gp3ml API contract registry: 71 stable exports, 56 experimental exports, 38 stable public classes
head(registry$exports)
#>                            name    stability present
#> 1    apply_gazepoint_calibrator       stable    TRUE
#> 2 apply_gazepoint_decision_rule experimental    TRUE
#> 3                 as_gp3ml_data experimental    TRUE
#> 4 assert_gp3ml_engine_available experimental    TRUE
#> 5         assert_gp3ml_use_case       stable    TRUE
#> 6  assess_gazepoint_calibration       stable    TRUE
registry$policy
#>                  contract
#> 1  exported_function_name
#> 2         public_s3_class
#> 3        function_formals
#> 4 named_return_components
#>                                                                  stable_rule
#> 1                                No removal or rename within the 0.2.x line.
#> 2                                No removal or rename within the 0.2.x line.
#> 3         Existing arguments retain meaning; new arguments require defaults.
#> 4 Existing named components retain meaning; additive components are allowed.
```

## Audit the currently loaded package

``` r

audit <- audit_gp3ml_api_stability(registry)
audit
#>  gp3ml API stability audit: pass
#>                          check status n_issues
#>         stable_exports_present   pass        0
#>          declared_exports_only   pass        0
#>  stable_public_classes_present   pass        0
plot(audit)
```

![](api-stability-contracts_files/figure-html/audit-1.png)

A failure indicates removal of an established export or registered
public class. An undeclared export is reviewable rather than silently
accepted.

## Inspect an object schema

``` r

example_data <- data.frame(
  participant_id = rep(sprintf("P%02d", 1:8), each = 2),
  trial_id = sprintf("T%02d", 1:16),
  stimulus_id = rep(c("S01", "S02"), 8),
  assigned_condition = rep(c("A", "B"), 8),
  stringsAsFactors = FALSE
)

task <- declare_gazepoint_task(
  data = example_data,
  outcome = "assigned_condition",
  purpose = "Discriminate an experimentally assigned condition using predeclared observed variables",
  task_type = "classification",
  unit_id = "trial_id",
  participant_id = "participant_id",
  stimulus_id = "stimulus_id",
  generalization_target = "new_participants",
  positive = "B",
  observed_outcome = TRUE,
  sensitive_outcome = FALSE
)

validation <- validate_gp3ml_object_contract(task)
validation
#>  gp3ml object contract: pass
#>                    check status
#>  registered_public_class   pass
#>         named_components   pass
#>        schema_observable   pass
#>                                               detail
#>                                           gp3ml_task
#>             Named components are structurally valid.
#>  Schema can be represented by gp3ml_object_schema().
validation$schema
#>                component     class    typeof length nrow ncol
#> 1                outcome character character      1   NA   NA
#> 2                purpose character character      1   NA   NA
#> 3              task_type character character      1   NA   NA
#> 4                unit_id character character      1   NA   NA
#> 5         participant_id character character      1   NA   NA
#> 6            stimulus_id character character      1   NA   NA
#> 7  generalization_target character character      1   NA   NA
#> 8               positive character character      1   NA   NA
#> 9       observed_outcome   logical   logical      1   NA   NA
#> 10     sensitive_outcome   logical   logical      1   NA   NA
#> 11            created_at character character      1   NA   NA
#> 12                levels character character      2   NA   NA
#> 13              negative character character      1   NA   NA
```

The contract policy is additive: established named components retain
their meaning, while compatible additions remain possible.
