0.1\_table\_one
================
Darren S Thomas
16 June, 2020

# read\_data

``` r
# create list of filenames to read from
y <- list(
  "data/cohort_nc.csv",
  "data/cohort_iptw.csv",
  "data/cohort_em.csv",
  "data/cohort_psm.csv"
)

# read cohorts from .csv
z <- map(
  .x = y,
  ~ read_csv(
    file = .x,
    col_types = cols(
      treatment = col_factor(levels = c('eylea', 'avastin'))
    ))
)

# name each element of list
names(z) <- c('nc', 'iptw', 'em', 'psm')

# extract each elelment of list as tbl
nc <- z %>% pluck("nc")

iptw <- z %>% pluck("iptw")
  
em <- z %>% pluck("em")

psm <- z %>% pluck("psm")
```

``` r
# source fnc
source("fnc/table_one.R")
```

# nc

``` r
table_one(nc) %>% 
  knitr::kable()
```

    ## # A tibble: 2 x 11
    ##   treatment female_n female_prop age_median age_iqr age_min age_max va_median
    ##   <fct>        <int>       <dbl>      <dbl>   <dbl>   <dbl>   <dbl>     <dbl>
    ## 1 eylea         2758        0.63         81      11      51     102        55
    ## 2 avastin         39        0.6          79      12      58      91        50
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>

| treatment | female\_n | female\_prop | age\_median | age\_iqr | age\_min | age\_max | va\_median | va\_iqr | va\_min | va\_max |
| :-------- | --------: | -----------: | ----------: | -------: | -------: | -------: | ---------: | ------: | ------: | ------: |
| eylea     |      2758 |         0.63 |          81 |       11 |       51 |      102 |         55 |   23.75 |      25 |      73 |
| avastin   |        39 |         0.60 |          79 |       12 |       58 |       91 |         50 |   18.00 |      25 |      70 |

# iptw

Calculating the weighted baseline characteristics for iptw cohort is not
straightforward and therefore we will rely on available solutions.

``` r
iptw <- iptw %>%
  # categorical vars must be as factors
  mutate(gender = factor(gender, levels = c('M', 'F')))

iptw.svy <- survey::svydesign(
  ids = ~0, # no hierachy
  strata = NULL,
  weights = iptw$ipw,
  nest = FALSE,
  data = iptw
)
```

``` r
tableone::svyCreateTableOne(
  vars = c('gender', 'age', 'baseline_etdrs'),
  strata = 'treatment',
  data = iptw.svy
) %>% 
  print(
    nonnormal = c('age', 'baseline_etdrs'),
    contDigits = 0)
```

    ##                                Stratified by treatment
    ##                                 eylea           avastin        p      test   
    ##   n                             8610.7          131.3                        
    ##   gender = F (%)                5433.8 (63.1)    80.8 (61.5)    0.797        
    ##   age (median [IQR])                82 [76, 86]    80 [75, 87]  0.546 nonnorm
    ##   baseline_etdrs (median [IQR])     55 [44, 64]    53 [43, 61]  0.373 nonnorm

``` r
# ranges are unaffected
table_one(iptw) %>% 
    knitr::kable()
```

    ## # A tibble: 2 x 11
    ##   treatment female_n female_prop age_median age_iqr age_min age_max va_median
    ##   <fct>        <int>       <dbl>      <dbl>   <dbl>   <dbl>   <dbl>     <dbl>
    ## 1 eylea         2623        0.63         80      10      51     102        54
    ## 2 avastin         39        0.6          79      12      58      91        50
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>

| treatment | female\_n | female\_prop | age\_median | age\_iqr | age\_min | age\_max | va\_median | va\_iqr | va\_min | va\_max |
| :-------- | --------: | -----------: | ----------: | -------: | -------: | -------: | ---------: | ------: | ------: | ------: |
| eylea     |      2623 |         0.63 |          80 |       10 |       51 |      102 |         54 |      22 |      25 |      73 |
| avastin   |        39 |         0.60 |          79 |       12 |       58 |       91 |         50 |      18 |      25 |      70 |
| \# em     |           |              |             |          |          |          |            |         |         |         |

``` r
table_one(em) %>% 
    knitr::kable()
```

    ## # A tibble: 2 x 11
    ##   treatment female_n female_prop age_median age_iqr age_min age_max va_median
    ##   <fct>        <int>       <dbl>      <dbl>   <dbl>   <dbl>   <dbl>     <dbl>
    ## 1 eylea           28        0.67         80      11      66      91      53.5
    ## 2 avastin         28        0.67         80      11      66      91      53.5
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>

| treatment | female\_n | female\_prop | age\_median | age\_iqr | age\_min | age\_max | va\_median | va\_iqr | va\_min | va\_max |
| :-------- | --------: | -----------: | ----------: | -------: | -------: | -------: | ---------: | ------: | ------: | ------: |
| eylea     |        28 |         0.67 |          80 |       11 |       66 |       91 |       53.5 |   17.75 |      25 |      70 |
| avastin   |        28 |         0.67 |          80 |       11 |       66 |       91 |       53.5 |   17.75 |      25 |      70 |

# psm

``` r
table_one(psm) %>% 
    knitr::kable()
```

    ## # A tibble: 2 x 11
    ##   treatment female_n female_prop age_median age_iqr age_min age_max va_median
    ##   <fct>        <int>       <dbl>      <dbl>   <dbl>   <dbl>   <dbl>     <dbl>
    ## 1 eylea           40        0.62         79      11      55      93        55
    ## 2 avastin         39        0.6          79      12      58      91        50
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>

| treatment | female\_n | female\_prop | age\_median | age\_iqr | age\_min | age\_max | va\_median | va\_iqr | va\_min | va\_max |
| :-------- | --------: | -----------: | ----------: | -------: | -------: | -------: | ---------: | ------: | ------: | ------: |
| eylea     |        40 |         0.62 |          79 |       11 |       55 |       93 |         55 |      18 |      27 |      71 |
| avastin   |        39 |         0.60 |          79 |       12 |       58 |       91 |         50 |      18 |      25 |      70 |

# aflibercept (before aligning protocols)

``` r
# configure connection to mysql
source("src/kale_mysql.R")
```

``` sql
-- output.var = 'all.eylea'
SELECT patient_eye AS id,
treatment,
age_at_baseline AS age,
gender,
baseline_va AS baseline_etdrs
FROM amd_synthetic_eylea_arm_study_table;
```

``` r
# correct for if 1/60 snellen meters
all.eylea$baseline_etdrs[all.eylea$baseline_etdrs == -4] <- 4

# correct for it cf
all.eylea$baseline_etdrs[all.eylea$baseline_etdrs == -15] <- 2

# correct for if gm, lp, or nlp
all.eylea$baseline_etdrs[all.eylea$baseline_etdrs <= -30] <- 0

all.eylea %>% 
  as_tibble() %>% 
  na.omit() %>% 
  table_one()
```

    ## # A tibble: 1 x 11
    ##   treatment female_n female_prop age_median age_iqr age_min age_max va_median
    ##   <chr>        <int>       <dbl>      <dbl>   <dbl>   <int>   <int>     <dbl>
    ## 1 eylea        15860        0.63         81      11      16     103        60
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>
