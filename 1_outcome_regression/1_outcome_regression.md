outcome\_regression
================
Darren S Thomas
04 August, 2020

# read\_data

``` r
# create list of filenames to read from
y <- list(
  "../data/cohort_nc.csv",
  "../data/cohort_iptw.csv",
  "../data/cohort_em.csv",
  "../data/cohort_psm.csv"
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
names(z) <- c('uc', 'iptw', 'em', 'psm')

# extract each elelment of list as tbl
uc <- z %>% pluck("uc")

iptw <- z %>% pluck("iptw")
  
em <- z %>% pluck("em")

psm <- z %>% pluck("psm")
```

# source\_fncs

``` r
# source code to pre-process, run, and post-process glm (for em + psm)
source("../fnc/va_glm.R")
```

# uc

``` r
uc <- uc %>% 
  # add null weights
  mutate(weights = 1) %>% 
  va_glm()
```

``` r
# ≥ 15 letters
uc[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.308    0.0352    -33.4  2.51e-244    0.288     0.330
    ## 2 treatmentavastin    1.55     0.268       1.63 1.03e-  1    0.899     2.58

``` r
# ≥ 10 letetrs 
uc[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.563    0.0312    -18.4  8.23e-76    0.530     0.599
    ## 2 treatmentavastin    1.52     0.251       1.67 9.41e- 2    0.926     2.49

``` r
# > -15 letters
uc[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.119    0.0486   -43.9     0        0.108     0.130
    ## 2 treatmentavastin    0.858    0.431     -0.356   0.722    0.329     1.84

``` r
# extract .glm output
uc.glm <- uc %>% 
  select(
    outcome,
    tidy_output
  ) %>% 
  unnest(cols = tidy_output) %>% 
  mutate(method = "UC")

uc.glm
```

    ## # A tibble: 6 x 9
    ## # Groups:   outcome [3]
    ##   outcome term  estimate std.error statistic   p.value conf.low conf.high method
    ##   <chr>   <chr>    <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl> <chr> 
    ## 1 fiftee… (Int…    0.308    0.0352   -33.4   2.51e-244    0.288     0.330 UC    
    ## 2 fiftee… trea…    1.55     0.268      1.63  1.03e-  1    0.899     2.58  UC    
    ## 3 ten_ga… (Int…    0.563    0.0312   -18.4   8.23e- 76    0.530     0.599 UC    
    ## 4 ten_ga… trea…    1.52     0.251      1.67  9.41e-  2    0.926     2.49  UC    
    ## 5 fiftee… (Int…    0.119    0.0486   -43.9   0.           0.108     0.130 UC    
    ## 6 fiftee… trea…    0.858    0.431     -0.356 7.22e-  1    0.329     1.84  UC

# iptw

``` r
iptw <- iptw %>% 
  va_glm(weights = iptw$ipw)
```

``` r
# ≥ 15 letters
iptw[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.321    0.0253    -45.0    0        0.305     0.337
    ## 2 treatmentavastin    1.33     0.192       1.49   0.136    0.905     1.93

``` r
# ≥ 10 letetrs 
iptw[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.583    0.0225    -24.0  2.11e-127    0.558     0.609
    ## 2 treatmentavastin    1.40     0.177       1.89 5.93e-  2    0.984     1.97

``` r
# > -15 letters
iptw[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.116    0.0355   -60.6     0        0.108     0.124
    ## 2 treatmentavastin    0.902    0.300     -0.345   0.730    0.476     1.56

``` r
# extract .glm output
iptw.glm <- iptw %>% 
  select(
    outcome,
    tidy_output
  ) %>% 
  unnest(cols = tidy_output) %>% 
  mutate(method = "IPTW")

iptw.glm
```

    ## # A tibble: 6 x 9
    ## # Groups:   outcome [3]
    ##   outcome term  estimate std.error statistic   p.value conf.low conf.high method
    ##   <chr>   <chr>    <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl> <chr> 
    ## 1 fiftee… (Int…    0.321    0.0253   -45.0   0.           0.305     0.337 IPTW  
    ## 2 fiftee… trea…    1.33     0.192      1.49  1.36e-  1    0.905     1.93  IPTW  
    ## 3 ten_ga… (Int…    0.583    0.0225   -24.0   2.11e-127    0.558     0.609 IPTW  
    ## 4 ten_ga… trea…    1.40     0.177      1.89  5.93e-  2    0.984     1.97  IPTW  
    ## 5 fiftee… (Int…    0.116    0.0355   -60.6   0.           0.108     0.124 IPTW  
    ## 6 fiftee… trea…    0.902    0.300     -0.345 7.30e-  1    0.476     1.56  IPTW

# em

``` r
em <- em %>% 
  # add null weights
  mutate(weights = 1) %>% 
  va_glm()
```

``` r
# ≥ 15 letters
em[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.194     0.413     -3.96 0.0000736   0.0793     0.411
    ## 2 treatmentavastin    2.23      0.530      1.51 0.131       0.807      6.60

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
# > -15 letters
em[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.229     0.392    -3.77  0.000166   0.0985     0.468
    ## 2 treatmentavastin    0.709     0.589    -0.582 0.560      0.214      2.24

``` r
# extract .glm output
em.glm <- em %>% 
  select(
    outcome,
    tidy_output
  ) %>% 
  unnest(cols = tidy_output) %>% 
  mutate(method = "EM")

em.glm
```

    ## # A tibble: 6 x 9
    ## # Groups:   outcome [3]
    ##   outcome  term   estimate std.error statistic p.value conf.low conf.high method
    ##   <chr>    <chr>     <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl> <chr> 
    ## 1 fifteen… (Inte…    0.194     0.413    -3.96  7.36e-5   0.0793     0.411 EM    
    ## 2 fifteen… treat…    2.23      0.530     1.51  1.31e-1   0.807      6.60  EM    
    ## 3 ten_gain (Inte…    0.483     0.325    -2.24  2.52e-2   0.248      0.897 EM    
    ## 4 ten_gain treat…    1.49      0.449     0.891 3.73e-1   0.621      3.64  EM    
    ## 5 fifteen… (Inte…    0.229     0.392    -3.77  1.66e-4   0.0985     0.468 EM    
    ## 6 fifteen… treat…    0.709     0.589    -0.582 5.60e-1   0.214      2.24  EM

# psm

``` r
psm <- psm %>% 
  # add null weights
  mutate(weights = 1) %>% 
  va_glm()
```

``` r
# ≥ 15 letters
psm[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.413     0.273    -3.24  0.00119    0.236     0.693
    ## 2 treatmentavastin    1.16      0.380     0.380 0.704      0.548     2.45

``` r
# ≥ 10 letters 
psm[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.970     0.248    -0.124   0.901    0.594      1.58
    ## 2 treatmentavastin    0.884     0.351    -0.351   0.725    0.443      1.76

``` r
# > -15 letters
psm[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic     p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>       <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.121     0.400    -5.28  0.000000126   0.0502     0.247
    ## 2 treatmentavastin    0.843     0.586    -0.292 0.770         0.257      2.68

``` r
# extract .glm output
psm.glm <- psm %>% 
  select(
    outcome,
    tidy_output
  ) %>% 
  unnest(cols = tidy_output)%>% 
  mutate(method = "PSM")

psm.glm
```

    ## # A tibble: 6 x 9
    ## # Groups:   outcome [3]
    ##   outcome  term   estimate std.error statistic p.value conf.low conf.high method
    ##   <chr>    <chr>     <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl> <chr> 
    ## 1 fifteen… (Inte…    0.413     0.273    -3.24  1.19e-3   0.236      0.693 PSM   
    ## 2 fifteen… treat…    1.16      0.380     0.380 7.04e-1   0.548      2.45  PSM   
    ## 3 ten_gain (Inte…    0.970     0.248    -0.124 9.01e-1   0.594      1.58  PSM   
    ## 4 ten_gain treat…    0.884     0.351    -0.351 7.25e-1   0.443      1.76  PSM   
    ## 5 fifteen… (Inte…    0.121     0.400    -5.28  1.26e-7   0.0502     0.247 PSM   
    ## 6 fifteen… treat…    0.843     0.586    -0.292 7.70e-1   0.257      2.68  PSM

# forest\_plot

``` r
# bind .glm outputs
sup <- bind_rows(
  uc.glm,
  iptw.glm,
  em.glm,
  psm.glm
) %>% 
  # rename broom::tidy() outputs
  rename(
    or = estimate,
    lo95 = conf.low,
    hi95 = conf.high
  ) %>% 
  # 
  mutate(outcome = case_when(
    outcome == "fifteen_gain" ~ "≥ 15 letters",
    outcome == "ten_gain" ~ "≥ 10 letters",
    outcome == "fifteen_loss" ~ "≤ -15 letters"
  ))
```

``` r
# convert to point estimate and confidence intervals to strings (to keep trailing zeros for plot)

to_string <- function(
  var,
  n_digits = 2,
  n_small = 2){
    
  as.character(format(round(var, digits = n_digits), nsmall = n_small))
  
  }
```

``` r
sup <- sup %>% 
  mutate(
    or_lab = to_string(or),
    lo95_lab = to_string(lo95),
    hi95_lab = to_string(hi95),
    lab = str_c(
      str_trim(or_lab),
      "(",
      str_trim(lo95_lab),
      "-",
      str_trim(hi95_lab),
      ")"
    )
  )
```

``` r
# plot, faceted by adjustment
sup %>% 
  filter(term != "(Intercept)") %>% 
  mutate(
    method = factor(method, levels = c("PSM", "EM", "IPTW", "UC")),
    outcome = factor(outcome, levels = c('≥ 15 letters', '≥ 10 letters', '≤ -15 letters'))) %>% 
ggplot(aes(x = or, y = method)) +
  facet_grid(.~outcome) +
  # log scale
  scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4)) +
  # add line of no effect
  geom_vline(
    xintercept = 1,
    linetype = "dashed",
    colour = 'grey'
  ) +
  # add confidence intervals
  geom_errorbarh(aes(
    xmin = lo95,
    xmax = hi95,
    height = 0
  )) +
  # add point estimates
  geom_point(
    size = 7,
    shape = 18) +
  # add text for point estimates and confidence intervals
  geom_text(aes(
    family = 'Courier',
    label = lab),
    parse = FALSE,
    nudge_y = -0.2) +
  # ammend visuals
  labs(
    x = "Odds Ratio (95% Confidence Interval)",
    y = NULL) +
  theme(legend.position = "none")
```

![](1_outcome_regression_files/figure-gfm/unnamed-chunk-26-1.png)<!-- -->

``` r
# export as .tiff
ggsave(
  filename = "fig_3.tiff",
  plot = last_plot(),
  device = "tiff",
  path = "../figs",
  width = 178,
  height = 100,
  units = "mm",
  dpi = 300
)
```

    ## R version 4.0.2 (2020-06-22)
    ## Platform: x86_64-apple-darwin17.0 (64-bit)
    ## Running under: macOS Mojave 10.14.6
    ## 
    ## Matrix products: default
    ## BLAS:   /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRblas.dylib
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRlapack.dylib
    ## 
    ## locale:
    ## [1] en_GB.UTF-8/en_GB.UTF-8/en_GB.UTF-8/C/en_GB.UTF-8/en_GB.UTF-8
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] forcats_0.5.0   stringr_1.4.0   dplyr_1.0.0     purrr_0.3.4    
    ##  [5] readr_1.3.1     tidyr_1.1.0     tibble_3.0.3    ggplot2_3.3.2  
    ##  [9] tidyverse_1.3.0 broom_0.7.0    
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] tidyselect_1.1.0 xfun_0.15        haven_2.3.1      colorspace_1.4-1
    ##  [5] vctrs_0.3.2      generics_0.0.2   htmltools_0.5.0  yaml_2.2.1      
    ##  [9] utf8_1.1.4       blob_1.2.1       rlang_0.4.7      pillar_1.4.6    
    ## [13] glue_1.4.1       withr_2.2.0      DBI_1.1.0        dbplyr_1.4.4    
    ## [17] modelr_0.1.8     readxl_1.3.1     lifecycle_0.2.0  munsell_0.5.0   
    ## [21] gtable_0.3.0     cellranger_1.1.0 rvest_0.3.5      evaluate_0.14   
    ## [25] knitr_1.29       fansi_0.4.1      Rcpp_1.0.5       scales_1.1.1    
    ## [29] backports_1.1.8  jsonlite_1.7.0   farver_2.0.3     fs_1.4.2        
    ## [33] hms_0.5.3        digest_0.6.25    stringi_1.4.6    grid_4.0.2      
    ## [37] cli_2.0.2        tools_4.0.2      magrittr_1.5     crayon_1.3.4    
    ## [41] pkgconfig_2.0.3  ellipsis_0.3.1   MASS_7.3-51.6    xml2_1.3.2      
    ## [45] reprex_0.3.0     lubridate_1.7.9  assertthat_0.2.1 rmarkdown_2.3   
    ## [49] httr_1.4.1       rstudioapi_0.11  R6_2.4.1         compiler_4.0.2
