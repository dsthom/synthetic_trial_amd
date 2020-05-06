eylea\_em
================
Darren S Thomas
06 May, 2020

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

# no\_matching

``` r
# combine avastin (n 65) and eylea (n 4,471) arms
negative.control <- bind_rows(abc, ehr)
```

## intention\_to\_treat

``` r
negative.control <- negative.control %>% 
  va_glm()
```

``` r
# ≥ 15 letters
negative.control[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term            estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>              <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)        0.307    0.0353    -33.5  2.20e-245    0.287     0.329
    ## 2 treatmentavast…    1.55     0.268       1.65 9.99e-  2    0.902     2.59

``` r
# ≥ 10 letetrs 
negative.control[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.561    0.0312    -18.5  9.84e-77    0.528     0.596
    ## 2 treatmentavastin    1.53     0.251       1.69 9.11e- 2    0.929     2.50

``` r
# < 15 letters
negative.control[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          8.16    0.0480    43.8     0        7.44       8.98
    ## 2 treatmentavastin     1.20    0.431      0.432   0.666    0.561      3.14

# iptw

``` r
# source ipt code
source("fnc/inverse_probability_treatment.R")
```

``` r
# run ipt algorithm
iptw <- inverse_probability_treatment(abc, ehr)
```

## intention\_to\_treat

``` r
# run primary analysis fucntion
iptw <- iptw %>% 
  va_weighted_glm() ###!!!  r unify with va_glm.R
```

``` r
# ≥ 15 letters
iptw[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.275    0.0249    -51.8   0         0.262     0.289
    ## 2 treatmentavastin    1.55     0.192       2.29  0.0222    1.05      2.24

``` r
# ≥ 10 letetrs 
iptw[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term            estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>              <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)        0.515    0.0216    -30.7  1.49e-206    0.494     0.537
    ## 2 treatmentavast…    1.58     0.177       2.59 9.70e-  3    1.11      2.23

``` r
# < 15 letters
iptw[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          7.93    0.0325    63.7     0        7.44       8.45
    ## 2 treatmentavastin     1.20    0.300      0.621   0.534    0.697      2.28

# exact\_matching

``` r
# source exact_matching code
source("fnc/exact_matching.R")
```

``` r
# run exact_matching_algortihm
em <- exact_matching(abc, ehr)
```

## intention\_to\_treat

``` r
em <- em %>% 
  va_glm()
```

``` r
# ≥ 15 letters
em[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.194     0.413     -3.96  7.36e-5   0.0793     0.411
    ## 2 treatmentavastin    2.23      0.530      1.51  1.31e-1   0.807      6.60

``` r
# ≥ 10 letetrs 
em[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.483     0.325    -2.24   0.0252    0.248     0.897
    ## 2 treatmentavastin    1.49      0.449     0.891  0.373     0.621     3.64

``` r
# < 15 letters
em[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          4.37     0.392     3.77  0.000166    2.14      10.1 
    ## 2 treatmentavastin     1.41     0.589     0.582 0.560       0.446      4.67

# psm\_single\_iteration

``` r
# source psm code
source("fnc/propensity_score_matching.R")
```

``` r
# cheat solution while propensity_score_matching fnc optimised
psm <- read_csv("data/psm_first_iteration.csv")
```

## intention to treat

``` r
psm <- psm %>% 
  va_glm()
```

``` r
# ≥ 15 letters
psm[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          0.3      0.294     -4.09  4.32e-5    0.163     0.521
    ## 2 treatmentavastin     1.59     0.396      1.17  2.41e-1    0.736     3.51

``` r
# ≥ 10 letters 
psm[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.383     0.277     -3.46 0.000535    0.217     0.647
    ## 2 treatmentavastin    2.24      0.372      2.16 0.0305      1.09      4.71

``` r
# < 15 letters
psm[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term           estimate std.error statistic    p.value conf.low conf.high
    ##   <chr>             <dbl>     <dbl>     <dbl>      <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)        7.12     0.378     5.20     1.98e-7    3.61      16.2 
    ## 2 treatmentavas…     1.38     0.571     0.564    5.73e-1    0.452      4.43

# psm\_multiple\_iterations

zedd \<- propensity\_score\_matching( trial\_arm = abc, synthetic\_arm =
ehr, iterations = 1, caliper\_sd = 0.1 )
