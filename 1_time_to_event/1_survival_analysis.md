1\_survival\_analysis
================
Darren S Thomas
06 July, 2020

# read data

``` sql
SELECT *
FROM syn_avastin_eylea_censorship;
```

``` r
# convert sql import to tbl
censorship <- as_tibble(censorship)
```

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

# extract each elelment of list as tbl
nc <- z %>% pluck('nc')

iptw <- z %>% pluck('iptw')
  
em <- z %>% pluck('em')

psm <- z %>% pluck('psm')
```

``` r
# Surv requires weights

nc <- mutate(nc, weights = 1)
iptw <- rename(iptw, weights = ipw)
em <- mutate(em, weights = 1)
psm <- mutate(psm, weights = 1)
```

``` r
# source fncs
source("../fnc/survival_wrangle.R")   # joins censorship data to cohorts
source("../fnc/survival_km.R")        # models a survfit ovbject
source("../fnc/ggsurvplot_courier.R") # plots kaplan-meiers
```

# nc

``` r
#

nc.cens <- map2(
  .x = list(
    nc
  ),
  .y = list(
    '>=15',
    '>=10',
    '<=-15'),
  .f = ~ survival_wrangle(
    cohort_tbl = .x,
    pool_tbl = censorship,
    event = .y
  )
)

names(nc.cens) <- list(
    '>=15',
    '>=10',
    '<=-15')
```

``` r
#

nc.kms <- map(
  .x = nc.cens,
  ~ survival_km(
    data = .x,
    weights = weights
  )
)
```

``` r
#

nc.plots <- map2(
  .x = nc.kms,
  .y = nc.cens,
  ~ ggsurvplot_courier(
    fit = .x,
    data = .y
  )
)
```

# iptw

``` r
#

iptw.cens <- map2(
  .x = list(
    iptw
  ),
  .y = list(
    '>=15',
    '>=10',
    '<=-15'),
  .f = ~ survival_wrangle(
    cohort_tbl = .x,
    pool_tbl = censorship,
    event = .y
  )
)

names(iptw.cens) <- list(
    '>=15',
    '>=10',
    '<=-15')
```

``` r
#

iptw.kms <- map(
  .x = iptw.cens,
  ~ survival_km(
    data = .x,
    weights = weights
  )
)
```

``` r
#

iptw.plots <- map2(
  .x = iptw.kms,
  .y = iptw.cens,
  ~ ggsurvplot_courier(
    fit = .x,
    data = .y
  )
)
```

# em

``` r
#

em.cens <- map2(
  .x = list(
    em
  ),
  .y = list(
    '>=15',
    '>=10',
    '<=-15'),
  .f = ~ survival_wrangle(
    cohort_tbl = .x,
    pool_tbl = censorship,
    event = .y
  )
)

names(em.cens) <- list(
    '>=15',
    '>=10',
    '<=-15')
```

``` r
#

em.kms <- map(
  .x = em.cens,
  ~ survival_km(
    data = .x,
    weights = weights
  )
)
```

``` r
#

em.plots <- map2(
  .x = em.kms,
  .y = em.cens,
  ~ ggsurvplot_courier(
    fit = .x,
    data = .y
  )
)
```

# psm

``` r
#

psm.cens <- map2(
  .x = list(
    psm
  ),
  .y = list(
    '>=15',
    '>=10',
    '<=-15'),
  .f = ~ survival_wrangle(
    cohort_tbl = .x,
    pool_tbl = censorship,
    event = .y
  )
)

names(psm.cens) <- list(
    '>=15',
    '>=10',
    '<=-15')
```

``` r
#

psm.kms <- map(
  .x = psm.cens,
  ~ survival_km(
    data = .x,
    weights = weights
  )
)
```

``` r
#

psm.plots <- map2(
  .x = psm.kms,
  .y = psm.cens,
  ~ ggsurvplot_courier(
    fit = .x,
    data = .y
  )
)
```

# combine

``` r
plots <- c(
  nc.plots,
  iptw.plots,
  em.plots,
  psm.plots
)
```

``` r
# wrap individual elements
arrange_ggsurvplots(
  plots, 
  print = TRUE,
  ncol = 4,
  nrow = 3)
```

![](1_survival_analysis_files/figure-gfm/unnamed-chunk-19-1.png)<!-- -->

``` r
# save as object
a <- arrange_ggsurvplots(
  plots, 
  print = TRUE,
  ncol = 4,
  nrow = 3)
```

![](1_survival_analysis_files/figure-gfm/unnamed-chunk-20-1.png)<!-- -->

``` r
# export as .tiff
ggsave(
  filename = "fig_4.tiff",
  plot = a,
  device = "tiff",
  path = "../figs",
  width = 134,
  height = 100,
  units = "mm",
  dpi = 300
)
```

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
    ##  [1] survminer_0.4.7 ggpubr_0.3.0    keyring_1.1.0   forcats_0.5.0  
    ##  [5] stringr_1.4.0   dplyr_1.0.0     purrr_0.3.4     readr_1.3.1    
    ##  [9] tidyr_1.1.0     tibble_3.0.1    ggplot2_3.3.1   tidyverse_1.3.0
    ## [13] survival_3.1-12 patchwork_1.0.0
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] httr_1.4.1        RMySQL_0.10.20    jsonlite_1.7.0    splines_3.6.0    
    ##  [5] carData_3.0-4     modelr_0.1.8      assertthat_0.2.1  blob_1.2.1       
    ##  [9] cellranger_1.1.0  yaml_2.2.1        pillar_1.4.4      backports_1.1.7  
    ## [13] lattice_0.20-41   glue_1.4.1        digest_0.6.25     ggsignif_0.6.0   
    ## [17] rvest_0.3.5       colorspace_1.4-1  htmltools_0.4.0   Matrix_1.2-18    
    ## [21] pkgconfig_2.0.3   broom_0.5.6       haven_2.3.1       xtable_1.8-4     
    ## [25] scales_1.1.1      km.ci_0.5-2       openxlsx_4.1.5    rio_0.5.16       
    ## [29] KMsurv_0.1-5      farver_2.0.3      generics_0.0.2    car_3.0-8        
    ## [33] ellipsis_0.3.1    withr_2.2.0       cli_2.0.2         magrittr_1.5     
    ## [37] crayon_1.3.4      readxl_1.3.1      evaluate_0.14     fs_1.4.1         
    ## [41] fansi_0.4.1       nlme_3.1-148      rstatix_0.5.0     xml2_1.3.2       
    ## [45] foreign_0.8-71    tools_3.6.0       data.table_1.12.8 hms_0.5.3        
    ## [49] lifecycle_0.2.0   munsell_0.5.0     reprex_0.3.0      zip_2.0.4        
    ## [53] compiler_3.6.0    rlang_0.4.6       grid_3.6.0        rstudioapi_0.11  
    ## [57] labeling_0.3      rmarkdown_2.2     gtable_0.3.0      abind_1.4-5      
    ## [61] DBI_1.1.0         curl_4.3          R6_2.4.1          zoo_1.8-8        
    ## [65] gridExtra_2.3     lubridate_1.7.9   knitr_1.28        survMisc_0.5.5   
    ## [69] stringi_1.4.6     Rcpp_1.0.4.6      vctrs_0.3.1       dbplyr_1.4.4     
    ## [73] tidyselect_1.1.0  xfun_0.14
