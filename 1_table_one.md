0.1\_table\_one
================
Darren S Thomas
08 June, 2020

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

``` r
table_one(iptw) %>% 
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

# em

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
    ## 1 eylea           42        0.65         79      11      54      93        55
    ## 2 avastin         39        0.6          79      12      58      91        50
    ## # … with 3 more variables: va_iqr <dbl>, va_min <dbl>, va_max <dbl>

| treatment | female\_n | female\_prop | age\_median | age\_iqr | age\_min | age\_max | va\_median | va\_iqr | va\_min | va\_max |
| :-------- | --------: | -----------: | ----------: | -------: | -------: | -------: | ---------: | ------: | ------: | ------: |
| eylea     |        42 |         0.65 |          79 |       11 |       54 |       93 |         55 |      19 |      31 |      71 |
| avastin   |        39 |         0.60 |          79 |       12 |       58 |       91 |         50 |      18 |      25 |      70 |
