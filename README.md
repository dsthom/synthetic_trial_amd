# synthetic_trial_amd

An emulated target trial comparing I) the bevacizumab arm (n 65) of the ABC trial &mdash; a prospective, double-masked, multicentre randomised controlled trial undertaken in the United Kingdom during 2006–08 &mdash; with II) a synthetic arm from 31,151 eyes receiving aflibercept during routine care across 27 sites in England during 2012–18.

![Study design](/fig_1_readme.png)
**Workflow of emulated target trial estimating causal effects.** L, confounding variables (age, sex, baseline read); A, independent variable (bevacizumab vs. aflibercept); Y, dependent variable (Δ in visual acuity from baseline to week 54); M, mediating variable (number of maintenance injections received during the study period). Abbreviations: EHRs, Electronic Health Records; SOC, Standard Of Care; NC, Negative Control; IPTW, Inverse Probability of Treatment Weighting; EM, Exact Matching; PSM, Propensity Score Matching.

# Table of contents

- [Arms](#arms)
  * [Bevacizumav trial arm](#bevacizumav-trial-arm)
  * [Aflibercept synthetic arm](#aflibercept-synthetic-arm)
  
- [Quasi-randomsiation](#quasi-randomsiation)

- [Analyses](#analyses)
  * [Noninferiority](#noninferiority)
  * [Superiority](#superiority)
  * [Time-to-event](#time-to-event)

# Arms
## Bevacizumav trial arm 

Borrows the Bevacizumab arm from the ABC trial.

## Aflibercept synthetic arm 

Assembled from Electronic Health Records:

* `src/amd_irf_srf_large_tables.sql` retrieves all treatments and readings for eyes with a indication of AMD.
* `src/synthetic_eylea_arm_study_table.sql` retrieves vars and aligns all eyes in alignment with ABC and target-trial eligibility

# Quasi-randomsiation

In which numerous quasi-randomsiation methods are employed for conditioning on confounding variables (vars that are common causes of both x and y).

These cohorts are assembled in `0_cohorts_generation.Rmd` using bespoke functions listed below:

| Method | Function |
|:--------:|:----------:|
| Negative control | &mdash; |
| Inverse Probability Treatment Weighting | `fnc/inverse_probability_treatment.R` |
| Exact matching | `fnc/exact_matching.R`|
| Propensity Score Matching | `fnc/propensity_score_matching.R`|

These cohorts are then saved to `/data` as .csv and read in for each analyses.

# Analyses

Causal assumption of exchangeability visualised in `1_exchangeability`.
Baseline characteristics created in `1_table_one`.

## Noninferiority

Noninferiority analysis contained in `1_noninferiority`.

## Superiority

Superiority analysis contained in `1_superiority`.

## Time-to-event

Time-to-event analysis contained in `1_time_to_event`.
