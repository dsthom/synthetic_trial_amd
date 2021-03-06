0\_cohorts\_generation
================
Darren S Thomas
04 August, 2020

Run script once only to generate cohorts in order of:

  - read abc avastin arm from .csv and synthetic eylea arm from mysql
    server
  - assemble cohorts for nc, iptw, em, and psm
  - export cohorts to .csv (for use in outcome regression analysis)
  - export cohorts to mysql server (for use in survival analysis)

# read

``` r
# read trial arm
abc <- read_csv("../data/abc_patient_details.csv",
                col_types = cols(
                  id = col_character(),
                  age_at_baseline = col_integer(),
                  baseline_etdrs = col_integer(),
                  injection_count = col_integer(),
                  drug_recency = col_integer(),
                  study_exit_va = col_integer()
                )) %>% 
  rename(
    age = age_at_baseline,
    drug_load = injection_count) %>% 
  # reorder
  select(
    id,
    treatment, 
    age, 
    gender,
    baseline_etdrs,
    drug_load,
    drug_recency,
    study_exit_va) %>% 
  # restrict to avastin arm
  filter(treatment == "avastin")
```

``` sql
-- output.var = "ehr"
SELECT patient_eye AS id,
treatment,
age_at_baseline AS age,
gender,
baseline_va AS baseline_etdrs,
drug_load,
drug_recency,
study_exit_va
FROM amd_synthetic_eylea_arm_study_table
WHERE eligibility = 1;
```

``` r
# convert to tibble
ehr <- as.tibble(ehr)
```

# assemble

``` r
# source fncs
source("../fnc/inverse_probability_treatment.R")
source("../fnc/exact_matching.R")
source("../fnc/propensity_score_matching.R") 
```

``` r
# generate cohorts
## nc
nc <- bind_rows(abc, ehr)

## iptw
iptw <- inverse_probability_treatment(
  trial_arm = abc, 
  synthetic_arm = ehr,
  ps_trimming = TRUE)

## em
em <- exact_matching(
  trial_arm = abc,
  synthetic_arm = ehr)

## psm
psm <- propensity_score_matching(
  trial_arm = abc,
  synthetic_arm = ehr,
  caliper = 0.1,
  ps_trimming = TRUE)
```

# export\_to\_csv

``` r
# create list of objects to be exported
x <- list(
  nc,
  iptw,
  em,
  psm)

# create list of filenames to be exported to
y <- list(
  "../data/cohort_nc.csv",
  "../data/cohort_iptw.csv",
  "../data/cohort_em.csv",
  "../data/cohort_psm.csv"
)

# map over these two lists with write_csv
purrr::walk2(
  .x = x,
  .y = y,
  ~ write_csv(
    x = .x,
    path = .y
  )
)
```

# export\_to\_mysql

``` r
# create function to export cohort ids to kale (kale must be configured)
longform_to_kale <- function(
  .x,
  table_name
){
  # select only IDs
  .x <- .x %>% 
    select(
      id,
      treatment) ###!!! more variables may need to be selected (see sql script`)
  
  # write table to kale
  DBI::dbWriteTable(
    conn = kale,
    name = table_name,
    value = .x,
    overwrite = TRUE,
    row.names = FALSE
  )
}

# create list of objects to be exported
x <- list(
  nc,
  iptw,
  em,
  psm)

# create second list of tables names
y <- list(
  "syn_amd_eylea_cohort_nc",
  "syn_amd_eylea_cohort_iptw",
  "syn_amd_eylea_cohort_em",
  "syn_amd_eylea_cohort_psm"
)

# map over these two lists with the `longform_to_kale` fnc
purrr::walk2(
  .x = x,
  .y = y,
  ~ longform_to_kale(
    .x,
    table_name = .y
  )
)
```
