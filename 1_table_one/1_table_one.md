0.1\_table\_one
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
      ps = .fitted
    )
  
  # calculate ipw for iptw cohort, else weight = 1
  output <- output %>% 
    mutate(weight = if_else(
      cohort == "iptw", 
      case_when(treatment == "avastin" ~ 1 / ps,
                treatment == "eylea" ~ 1 / (1 - ps)),
      1))
  
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
    ##   n                           4471            65               
    ##   gender = F (%)              2817 (63.0)     39 (60.0)   0.062
    ##   age (mean (SD))            79.92 (7.97)  78.83 (7.52)   0.140
    ##   baseline_etdrs (mean (SD)) 52.10 (13.03) 50.92 (11.87)  0.094
    ##   ps (mean (SD))              0.50 (0.11)   0.52 (0.10)   0.174

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
  weights = ~ weight,
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
    ##   n                           8506.2          131.3               
    ##   gender = F (%)              5371.9 (63.2)    80.8 (61.5)   0.033
    ##   age (mean (SD))              79.63 (7.17)   80.05 (7.28)   0.058
    ##   baseline_etdrs (mean (SD))   51.51 (13.01)  51.93 (11.56)  0.034
    ##   ps (mean (SD))                0.50 (0.10)    0.49 (0.10)   0.088

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
    ##   n                             43            43               
    ##   gender = F (%)                29 (67.4)     29 (67.4)  <0.001
    ##   age (mean (SD))            80.33 (6.25)  80.33 (6.25)  <0.001
    ##   baseline_etdrs (mean (SD)) 51.44 (11.46) 51.44 (11.46) <0.001
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
    ##   gender = F (%)                39 (60.0)     39 (60.0)  <0.001
    ##   age (mean (SD))            78.48 (8.18)  78.83 (7.52)   0.045
    ##   baseline_etdrs (mean (SD)) 51.83 (12.42) 50.92 (11.87)  0.075
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
    ##  [1] keyring_1.1.0   broom_0.7.0     forcats_0.5.0   stringr_1.4.0  
    ##  [5] dplyr_1.0.0     purrr_0.3.4     readr_1.3.1     tidyr_1.1.0    
    ##  [9] tibble_3.0.3    ggplot2_3.3.2   tidyverse_1.3.0
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] Rcpp_1.0.5       lubridate_1.7.9  lattice_0.20-41  class_7.3-17    
    ##  [5] zoo_1.8-8        assertthat_0.2.1 digest_0.6.25    R6_2.4.1        
    ##  [9] cellranger_1.1.0 backports_1.1.8  reprex_0.3.0     labelled_2.5.0  
    ## [13] survey_4.0       evaluate_0.14    e1071_1.7-3      httr_1.4.1      
    ## [17] pillar_1.4.6     rlang_0.4.7      readxl_1.3.1     rstudioapi_0.11 
    ## [21] blob_1.2.1       Matrix_1.2-18    rmarkdown_2.3    splines_4.0.2   
    ## [25] RMySQL_0.10.20   munsell_0.5.0    compiler_4.0.2   modelr_0.1.8    
    ## [29] xfun_0.15        pkgconfig_2.0.3  htmltools_0.5.0  mitools_2.4     
    ## [33] tidyselect_1.1.0 tableone_0.12.0  fansi_0.4.1      crayon_1.3.4    
    ## [37] dbplyr_1.4.4     withr_2.2.0      MASS_7.3-51.6    grid_4.0.2      
    ## [41] jsonlite_1.7.0   gtable_0.3.0     lifecycle_0.2.0  DBI_1.1.0       
    ## [45] magrittr_1.5     scales_1.1.1     cli_2.0.2        stringi_1.4.6   
    ## [49] fs_1.4.2         xml2_1.3.2       ellipsis_0.3.1   generics_0.0.2  
    ## [53] vctrs_0.3.2      tools_4.0.2      glue_1.4.1       hms_0.5.3       
    ## [57] survival_3.2-3   yaml_2.2.1       colorspace_1.4-1 rvest_0.3.5     
    ## [61] knitr_1.29       haven_2.3.1
