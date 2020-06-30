iptw\_triangulation
================
Darren S Thomas
06 May, 2020

# setup

# outcome\_regression

``` r
# source iptw code
source("fnc/inverse_probability_treatment.R")

# source code to pre-process, run, and post-process weighted glm (for ipwt)
source("fnc/va_weighted_glm.R")
```

To run below code we need three tables for three arms:

  - avastin trial arm (n 65)
  - eylea ehr arm (n 4,471)
  - avastin ehr arm (n 128)

<!-- end list -->

``` r
# avastin trial arm
avastin.trial <- read_csv("data/abc_patient_details.csv",
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
-- eylea ehr arm
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

``` sql
-- avastin ehr arm
SELECT patient_eye AS id,
treatment,
age_at_baseline AS age,
gender,
baseline_va AS baseline_etdrs,
drug_load,
drug_recency,
study_exit_va
FROM amd_synthetic_avastin_arm_study_table
WHERE eligibility = 1;
```

``` r
# covnert sql imports to tibbles
eylea.ehr <- as.tibble(eylea.ehr)
avastin.ehr <- as.tibble(avastin.ehr)
```

``` r
# run ipt algorithm
iptw <- inverse_probability_treatment(
  trial_arm = avastin.ehr,   # ignore argument name
  synthetic_arm = eylea.ehr)
```

``` r
# run primary analysis function
iptw <- iptw %>% 
  va_weighted_glm() 
```

``` r
# ≥ 15 letters
iptw[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.275    0.0249    -51.8  0          0.262     0.289
    ## 2 treatmentavastin    0.561    0.188      -3.09 0.00203    0.382     0.798

``` r
# ≥ 10 letters
iptw[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term            estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>              <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)        0.515    0.0216    -30.7  1.49e-206    0.494     0.537
    ## 2 treatmentavast…    0.669    0.147      -2.74 6.07e-  3    0.498     0.886

``` r
# < 15 letters
iptw[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          7.93    0.0325    63.7     0        7.44       8.45
    ## 2 treatmentavastin     1.02    0.205      0.103   0.918    0.696      1.56

Now, we calculate the concordance in the estimands between our two
target trials.

``` r
concordance <- tribble(
  ~ trial_synthetic, ~ synthetic_synthetic,
  1.55, 0.56,
  1.58, 0.67,
  1.2, 1.02
)

lm(
  formula = trial_synthetic ~ synthetic_synthetic,
  data = concordance) %>% 
  broom::glance()
```

    ## # A tibble: 1 x 11
    ##   r.squared adj.r.squared  sigma statistic p.value    df logLik   AIC   BIC
    ##       <dbl>         <dbl>  <dbl>     <dbl>   <dbl> <int>  <dbl> <dbl> <dbl>
    ## 1     0.911         0.823 0.0889      10.3   0.192     2   4.65 -3.30 -6.01
    ## # … with 2 more variables: deviance <dbl>, df.residual <int>

``` r
concordance %>% 
  ggplot(aes(x = synthetic_synthetic, y = trial_synthetic)) +
  geom_point() +
  geom_smooth(method = "lm")
```

![](2020_iptw_triangulation_files/figure-gfm/unnamed-chunk-12-1.png)<!-- -->

# delinieating\_avastin\_protocol

We know that Avastin was prescribed PRN during every 6 weeks the ABC
trial, but how frequently during routine care?

128 of 2,056 eyes recieving 1.25 mg Avastin were eligible.

``` sql
SELECT i.patient_eye, 
       i.EncounterDate AS encounter_date,
       i.InjectedDrugDesc AS injected_drug_desc,
       cumulative_injection_count,
       days_since_last_injection
FROM nvAMD_injections i
INNER JOIN amd_synthetic_avastin_arm_study_table s
ON i.patient_eye = s.patient_eye
WHERE s.eligibility = 1 AND
      i.EncounterDate > s.third_injection_date AND -- maintenance injections only
      i.EncounterDate < s.study_exit
; 
```

``` r
avastin.injections <- avastin.injections %>% 
  as_tibble() %>% 
  arrange(
    patient_eye,
    encounter_date
  ) %>% 
  mutate(encounter_date = lubridate::ymd(encounter_date))
```

``` r
# injection intervals vs year
avastin.injections %>% 
  mutate(encounter_year = lubridate::year(encounter_date)) %>% 
  group_by(encounter_year) %>% 
  summarise(
    mean_intervals = round(mean(days_since_last_injection), 0),
    median_intervals = round(median(days_since_last_injection), 0)
  ) %>% 
  ggplot(aes(x = as.factor(encounter_year), y = median_intervals)) +
  geom_bar(stat = "identity") +
  geom_hline(yintercept = 8 * 7) +
  scale_y_continuous(breaks = seq(0, 110, 10)) +
  labs(
    title = "Avastin treatment frequency in routine care is highly variable",
    x = "Calendar year of administration",
    y = "Median days since previous injection")
```

![](2020_iptw_triangulation_files/figure-gfm/unnamed-chunk-15-1.png)<!-- -->
