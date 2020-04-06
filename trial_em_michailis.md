trial\_em\_michailis
================
Darren S Thomas
06 April, 2020

Code to wrangle data for Michails in wide-form.

# setup

# read\_from\_csv

``` r
abc <- read_csv("data/abc_patient_details.csv",
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

# import\_from\_mysql

``` sql
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
ehr <- as.tibble(ehr)
```

# exact\_matching

``` r
# source exact_matching code
source("fnc/exact_matching.R")
```

``` r
# run exact_matching_algortihm
em <- exact_matching(abc, ehr)
```

``` r
em.wide <- em %>% 
  # drop unneeded variables
  select(- drug_recency) %>% 
  # separate by treatment 
  group_by(treatment) %>% 
  group_split()
```

Now, obtain va measurements from kale.

ABC.

``` sql
SELECT id, 
       treatment, 
       week,
       etdrs
FROM abc_va_longform
WHERE treatment = 'avastin';
```

``` r
abc.va <- abc.va %>% 
  mutate(id = as.character(id)) %>% 
  select(- treatment) %>% 
  filter(week > 0)
```

``` r
em.wide[[1]] <- em.wide[[1]] %>% 
  # append va measurements
  left_join(
    abc.va,
    by = "id") 

# pivot wider
  em.wide[[1]] <-  pivot_wider(
    data = em.wide[[1]],
    names_from = week,
    values_from = etdrs,
    values_fill = NULL,
    names_prefix = "week_")
```

EHR.

``` sql
SELECT s.patient_eye AS id,
       DATEDIFF(v.EncounterDate, s.baseline_eylea_date) AS days_since_baseline,
       CEIL(DATEDIFF(v.EncounterDate, s.baseline_eylea_date) / 7) AS week,
       MAX(v.max_etdrs) AS etdrs
FROM amd_synthetic_eylea_arm_study_table s
LEFT JOIN nvAMD_visual_acuity v
ON s.patient_eye = v.patient_eye
WHERE s.eligibility = 1 AND
      v.EncounterDate > s.baseline_eylea_date AND
      v.EncounterDate <= s.study_exit
GROUP BY id, week;       
```

``` r
# imput negative etdrs to 0.
ehr.va$etdrs[ehr.va$etdrs < 0] <- 0
```

``` r
ehr.va <- ehr.va %>% 
  # keep measurements only for those matched
  filter(id %in% em.wide[[2]]$id) %>% 
  # remove measurements taken before week 4
  filter(week >= 3) %>% 
  # drop days_since_baseline
  select(- days_since_baseline)
```

``` r
em.wide[[2]] <- em.wide[[2]] %>% 
  # append va measurements
  left_join(
    ehr.va,
    by = "id")

# pivot wider
  em.wide[[2]] <-  pivot_wider(
    data = em.wide[[2]],
    names_from = week,
    values_from = etdrs,
    values_fill = NULL,
    names_prefix = "week_")
```

``` r
# reorder week columns in numerical order
range(ehr.va$week)
```

    ## [1]  4 58

``` r
n_seq <- seq(
  from = min(ehr.va$week),
  to = max(ehr.va$week)
)

week_seq <- str_c("week_", n_seq)
```

``` r
em.wide[[2]] <- select(em.wide[[2]],
              1:7,
              week_seq)
```

``` r
# combine list of two tables
exact_matches <- bind_rows(em.wide[[2]],
               em.wide[[1]]) %>% 
  write_csv("data/exact_matched_wide.csv")
```
