0.1\_table\_one
================
Darren S Thomas
14 July, 2020

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
names(z) <- c('nc', 'iptw', 'em', 'psm')
```

``` r
# merge to a single tbl
zz <- bind_rows(z, .id = "cohort") %>% 
  # 
  select(cohort:baseline_etdrs)
```

``` r
# create assign_ps fnc
assign_ps <- function(
  tbl
){

  # source propensity model
  source("../src/propensity_model.R")

  # predict Pr of treatment(Avastin == 1)
  output <- augment(
   x = propensity_model,
   newdata = tbl,
   type.predict = "response") %>% 
    rename(
      ps = .fitted,
      ps_se = .se.fit
    )
  
  # calculate ipw for iptw cohhort, else weight = 1
  output <- output %>% 
    mutate(weight = if_else(cohort == "iptw", 1 / ps, 1))
  
  output
  }
```

``` r
# score Pr
exc <- assign_ps(tbl = zz) %>% 
  # refactor sex
  mutate(gender = factor(gender, levels = c('M', 'F')))
```

# nc

``` r
tableone::CreateTableOne(
  vars = c("gender", "age", "baseline_etdrs", "ps"),
  strata = "treatment",
  data = filter(exc, cohort == "nc"),
  test = FALSE
) %>% 
print(smd = TRUE)
```

    ##                             Stratified by treatment
    ##                              eylea         avastin       SMD   
    ##   n                           4366            65               
    ##   gender = F (%)              2758 (63.2)     39 (60.0)   0.065
    ##   age (mean (SD))            79.90 (7.96)  78.83 (7.52)   0.138
    ##   baseline_etdrs (mean (SD)) 52.12 (13.03) 50.92 (11.87)  0.096
    ##   ps (mean (SD))              0.50 (0.11)   0.52 (0.10)   0.173

# iptw

Calculating the weighted baseline characteristics requires an addition
step using the `survey` package.

``` r
# subset ipw so we are sure weights align with rows
iptw <- filter(exc, cohort == "iptw")
```

``` r
iptw.svy <- survey::svydesign(
  ids = ~ 0, # no hierarchy
  strata = NULL,
  weights = iptw$weight,
  nest = FALSE,
  data = iptw
)
```

``` r
tableone::svyCreateTableOne(
  vars = c("gender", "age", "baseline_etdrs", "ps"),
  strata = "treatment",
  data = iptw.svy,
  test = FALSE
) %>% 
  print(smd = TRUE)
```

    ##                             Stratified by treatment
    ##                              eylea           avastin        SMD   
    ##   n                           8610.7          131.3               
    ##   gender = F (%)              5433.8 (63.1)    80.8 (61.5)   0.032
    ##   age (mean (SD))              80.80 (7.12)   80.05 (7.28)   0.104
    ##   baseline_etdrs (mean (SD))   52.90 (12.68)  51.93 (11.56)  0.080
    ##   ps (mean (SD))                0.48 (0.10)    0.49 (0.10)   0.139

# em

``` r
tableone::CreateTableOne(
  vars = c("gender", "age", "baseline_etdrs", "ps"),
  strata = "treatment",
  data = filter(exc, cohort == "em"),
  test = FALSE
) %>% 
print(smd = TRUE)
```

    ##                             Stratified by treatment
    ##                              eylea         avastin       SMD   
    ##   n                             42            42               
    ##   gender = F (%)                28 (66.7)     28 (66.7)  <0.001
    ##   age (mean (SD))            80.21 (6.28)  80.21 (6.28)  <0.001
    ##   baseline_etdrs (mean (SD)) 51.60 (11.55) 51.60 (11.55) <0.001
    ##   ps (mean (SD))              0.50 (0.09)   0.50 (0.09)  <0.001

# psm

``` r
tableone::CreateTableOne(
  vars = c("gender", "age", "baseline_etdrs", "ps"),
  strata = "treatment",
  data = filter(exc, cohort == "psm"),
  test = FALSE
) %>% 
print(smd = TRUE)
```

    ##                             Stratified by treatment
    ##                              eylea         avastin       SMD   
    ##   n                             65            65               
    ##   gender = F (%)                40 (61.5)     39 (60.0)   0.032
    ##   age (mean (SD))            77.94 (7.55)  78.83 (7.52)   0.118
    ##   baseline_etdrs (mean (SD)) 53.34 (12.31) 50.92 (11.87)  0.200
    ##   ps (mean (SD))              0.52 (0.10)   0.52 (0.10)   0.001

# pre-alignment

To what extend did exchangeability hold pre-alignment?

``` r
# configure connection to mysql
source("../src/kale_mysql.R")
```

``` sql
-- output.var = 'pre'
SELECT patient_eye AS id,
treatment,
age_at_baseline AS age,
gender,
baseline_va AS baseline_etdrs
FROM amd_synthetic_eylea_arm_study_table;
```

``` r
pre <- pre %>% 
  # convert to tbl
  as_tibble() %>% 
  # exclude those with missing data
  drop_na(gender, age, baseline_etdrs) %>% 
  # add cohort
  mutate(cohort = "prealignment")
```

``` r
# assign ps 
pre.ps <- assign_ps(tbl = pre) %>% 
  # add avastin trial arm
  bind_rows(filter(exc, cohort == "nc" & treatment == "avastin")) %>% 
  # refactor treatment and sex
  mutate(
    treatment = factor(treatment, levels = c('eylea', 'avastin')),
    gender = factor(gender, levels = c('M', 'F'))
  )
```

``` r
tableone::CreateTableOne(
  vars = c("gender", "age", "baseline_etdrs", "ps"),
  strata = "treatment",
  data = pre.ps,
  test = FALSE
) %>% 
print(smd = TRUE)
```

    ##                             Stratified by treatment
    ##                              eylea         avastin       SMD   
    ##   n                          25134            65               
    ##   gender = F (%)             15860 (63.1)     39 (60.0)   0.064
    ##   age (mean (SD))            79.96 (8.25)  78.83 (7.52)   0.143
    ##   baseline_etdrs (mean (SD)) 55.96 (17.32) 50.92 (11.87)  0.339
    ##   ps (mean (SD))              0.48 (0.12)   0.52 (0.10)   0.343

    ## R version 3.6.0 (2019-04-26)
    ## Platform: x86_64-apple-darwin15.6.0 (64-bit)
    ## Running under: macOS Mojave 10.14.6
    ## 
    ## Matrix products: default
    ## BLAS:   /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRblas.0.dylib
    ## LAPACK: /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRlapack.dylib
    ## 
    ## locale:
    ## [1] en_GB.UTF-8/en_GB.UTF-8/en_GB.UTF-8/C/en_GB.UTF-8/en_GB.UTF-8
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] keyring_1.1.0   broom_0.5.6     forcats_0.5.0   stringr_1.4.0  
    ##  [5] dplyr_1.0.0     purrr_0.3.4     readr_1.3.1     tidyr_1.1.0    
    ##  [9] tibble_3.0.2    ggplot2_3.3.2   tidyverse_1.3.0
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] Rcpp_1.0.4.6     lubridate_1.7.9  lattice_0.20-41  class_7.3-17    
    ##  [5] zoo_1.8-8        assertthat_0.2.1 digest_0.6.25    R6_2.4.1        
    ##  [9] cellranger_1.1.0 backports_1.1.8  reprex_0.3.0     labelled_2.4.0  
    ## [13] survey_4.0       evaluate_0.14    e1071_1.7-3      httr_1.4.1      
    ## [17] pillar_1.4.4     rlang_0.4.6      readxl_1.3.1     rstudioapi_0.11 
    ## [21] blob_1.2.1       Matrix_1.2-18    rmarkdown_2.2    splines_3.6.0   
    ## [25] RMySQL_0.10.20   munsell_0.5.0    compiler_3.6.0   modelr_0.1.8    
    ## [29] xfun_0.14        pkgconfig_2.0.3  htmltools_0.4.0  mitools_2.4     
    ## [33] tidyselect_1.1.0 tableone_0.11.1  fansi_0.4.1      crayon_1.3.4    
    ## [37] dbplyr_1.4.4     withr_2.2.0      MASS_7.3-51.6    grid_3.6.0      
    ## [41] nlme_3.1-148     jsonlite_1.7.0   gtable_0.3.0     lifecycle_0.2.0 
    ## [45] DBI_1.1.0        magrittr_1.5     scales_1.1.1     cli_2.0.2       
    ## [49] stringi_1.4.6    fs_1.4.1         xml2_1.3.2       ellipsis_0.3.1  
    ## [53] generics_0.0.2   vctrs_0.3.1      tools_3.6.0      glue_1.4.1      
    ## [57] hms_0.5.3        survival_3.1-12  yaml_2.2.1       colorspace_1.4-1
    ## [61] rvest_0.3.5      knitr_1.28       haven_2.3.1
