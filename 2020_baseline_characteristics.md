2020\_baseline\_characteristics
================
Darren S Thomas
01 April, 2020

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

# baseline\_characteristics

``` r
abc %>% 
  select(
    age,
    gender,
    baseline_etdrs
  ) %>% 
  mutate(gender = factor(gender)) %>% 
  skimr::skim()
```

    ## Skim summary statistics
    ##  n obs: 65 
    ##  n variables: 3 
    ## 
    ## ── Variable type:factor ────────────────────────────────────────────────────────────────────────────────────────────────
    ##  variable missing complete  n n_unique          top_counts ordered
    ##    gender       0       65 65        2 F: 39, M: 26, NA: 0   FALSE
    ## 
    ## ── Variable type:integer ───────────────────────────────────────────────────────────────────────────────────────────────
    ##        variable missing complete  n  mean    sd p0 p25 p50 p75 p100
    ##             age       0       65 65 78.83  7.52 58  74  79  86   91
    ##  baseline_etdrs       0       65 65 50.92 11.87 25  43  50  61   70
    ##      hist
    ##  ▁▂▂▅▇▅▅▇
    ##  ▂▃▅▇▅▅▇▆

``` r
ehr %>% 
  select(
    age,
    gender,
    baseline_etdrs
  ) %>% 
  mutate(gender = factor(gender)) %>% 
  skimr::skim()
```

    ## Skim summary statistics
    ##  n obs: 4471 
    ##  n variables: 3 
    ## 
    ## ── Variable type:factor ────────────────────────────────────────────────────────────────────────────────────────────────
    ##  variable missing complete    n n_unique              top_counts ordered
    ##    gender       0     4471 4471        2 F: 2817, M: 1654, NA: 0   FALSE
    ## 
    ## ── Variable type:integer ───────────────────────────────────────────────────────────────────────────────────────────────
    ##        variable missing complete    n  mean    sd p0 p25 p50 p75 p100
    ##             age       0     4471 4471 79.92  7.97 51  75  81  86  102
    ##  baseline_etdrs       0     4471 4471 52.1  13.03 25  40  55  64   73
    ##      hist
    ##  ▁▁▂▅▇▇▂▁
    ##  ▃▃▃▅▇▆▆▆
