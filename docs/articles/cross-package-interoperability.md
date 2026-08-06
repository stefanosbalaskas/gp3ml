# Cross-Package Interoperability Contracts

## Boundary, not duplication

The interoperability layer does not import raw Gazepoint files, process
biometric signals, or perform sequence analysis. Those remain upstream
responsibilities.

``` r

gp3ml_interop_contracts()
#>   source_package
#> 1       gp3tools
#> 2   gpbiometrics
#> 3   gp3sequences
#> 4   study_design
#> 5         custom
#>                                                   upstream_responsibility
#> 1 Gazepoint import, validation, gaze/fixation/AOI/transition preparation.
#> 2               EDA/HR/DIAL/IBI preparation and signal-quality summaries.
#> 3  Ordered-sequence validation, encoding, summaries, motifs, transitions.
#> 4 Experimentally assigned labels and prespecified study-design variables.
#> 5                  Externally prepared observed, non-sensitive variables.
#>                                                                                                  gp3ml_responsibility
#> 1 Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.
#> 2 Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.
#> 3 Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.
#> 4 Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.
#> 5 Role declaration, provenance, leakage-safe splitting/resampling, modelling, evaluation, uncertainty, and reporting.
#>   duplicates_upstream_preprocessing
#> 1                             FALSE
#> 2                             FALSE
#> 3                             FALSE
#> 4                             FALSE
#> 5                             FALSE
```

## Prepared handoffs

``` r

bundle <- simulate_gazepoint_research_handoffs(
  n_participants = 12L,
  n_stimuli = 3L,
  seed = 3201L
)
bundle
#>  gp3ml research bundle: 3 sources; outcome=assigned_condition; target=new_participants

gaze_validation <- validate_gazepoint_handoff(bundle$handoffs$gp3tools)
gaze_validation
#>  gp3ml handoff validation: pass
#>               check status
#>    supported_source   pass
#>        tabular_data   pass
#>   join_keys_present   pass
#>  join_keys_complete   pass
#>    join_keys_unique   pass
#>  predictors_present   pass
#>     outcome_present   pass
#>   data_hash_matches   pass
#>                                                              detail
#>                                                            gp3tools
#>                                                 36 rows x 8 columns
#>                               participant_id, trial_id, stimulus_id
#>                                         No missing join-key values.
#>                                       Composite join key is unique.
#>  valid_gaze_prop, fixation_count, mean_fixation_ms, gaze_dispersion
#>                                                  assigned_condition
#>                                         Handoff data are unchanged.
plot(gaze_validation)
```

![](cross-package-interoperability_files/figure-html/handoffs-1.png)

## Combine only after validation

``` r

combined <- combine_gazepoint_handoffs(
  bundle$handoffs,
  keys = bundle$keys
)
combined
#>  gp3ml handoff bundle: 3 sources, 36 joined rows
head(as_gp3ml_data(combined))
#>   participant_id trial_id stimulus_id assigned_condition valid_gaze_prop
#> 1           P001   T00001         S01                  A       0.8042958
#> 2           P002   T00002         S01                  B       0.9861274
#> 3           P003   T00003         S01                  A       0.8595829
#> 4           P004   T00004         S01                  B       0.9394516
#> 5           P005   T00005         S01                  A       0.9499491
#> 6           P006   T00006         S01                  B       0.9114933
#>   fixation_count mean_fixation_ms gaze_dispersion eda_valid_prop hr_valid_prop
#> 1              5         249.4945       0.3123735      0.8789096     0.9249897
#> 2              9         249.6495       0.3129274      0.9198267     1.0000000
#> 3              5         262.8509       0.2911562      0.9153236     0.9871083
#> 4              9         269.6437       0.1767864      0.9896786     0.9492468
#> 5              9         258.2238       0.3265558      0.9045170     0.9851544
#> 6              7         231.5134       0.2586631      0.9898708     0.9493813
#>   ibi_valid_prop sequence_length unique_state_count transition_rate
#> 1      0.9235095               6                  2       0.6087000
#> 2      0.8933526              11                  2       0.6243513
#> 3      0.8776888              12                  6       0.5684036
#> 4      0.9722860               9                  3       0.6700565
#> 5      0.9023553               4                  6       0.6221709
#> 6      0.9732340              12                  3       0.5557973
```

The resulting table is a modelling handoff. It does not imply that
`gp3ml` performed the upstream preprocessing represented by those
columns.
