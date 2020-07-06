exchangeability
================
Darren S Thomas
06 July, 2020

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

# add var to identify each cohort when lists are merged
z <- map2(
  .x = z,
  .y = list('nc', 'iptw', 'em', 'psm'),
  ~ mutate(
    .x,
    cohort = .y
  )
)

# add weight var (ipw weights will be updated later)
z <- map(
  .x = z,
  ~ mutate(
    .x,
    weight = 1)
)

# select only cont. confounders
z <- map(
  .x = z,
  ~ select(.x, id, age, baseline_etdrs, cohort, treatment, weight)
)

# combine individual elements into a singl df
zz <- do.call(rbind.data.frame, z)
```

``` r
# pivot longer
zz <- zz %>% 
  pivot_longer(
    cols = age:baseline_etdrs,
    names_to = "var",
    values_to = "unit"
  )
```

``` r
# assign weights for iptw
iptw <- read_csv("../data/cohort_iptw.csv") %>% 
  select(id, treatment, age, baseline_etdrs, weight = ipw) %>% 
  mutate(cohort = "iptw") %>% 
  pivot_longer(
    cols = age:baseline_etdrs,
    names_to = "var",
    values_to = "unit"
  )

zz <- zz %>% 
  filter(cohort != "iptw") %>% 
  bind_rows(iptw)
```

``` r
# assign facet labels to vectors
cohort_lbl <- c(
  "nc" = "NC", 
  "iptw" = "IPTW", 
  "em" = "EM", 
  "psm" = "PSM")

var_lbl <- c(
  "age" = "Age at baseline (years)", 
  "baseline_etdrs" = "Baseline read (ETDRS letters)")

# plot
zz %>% 
  mutate(cohort = factor(cohort, levels = c("nc", "iptw", "em", "psm"))) %>% 
  ggplot(aes(x = unit, colour = treatment, weight = weight)) +
  facet_grid(
    cohort ~ var,
    scales = "free_x",
    labeller = labeller(
      var = var_lbl,
      cohort = cohort_lbl
    )) +
  geom_density(alpha = 0.5) +
  scale_colour_discrete(
    name = NULL,
    labels = c("Aflibercept", "Eylea")) +
  labs(
    x = NULL,
    y = "Density")
```

![](1_exchangeability_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r
# export as .tiff
ggsave(
  filename = "exchangeability.tiff",
  plot = last_plot(),
  device = "tiff",
  path = "../figs",
  width = 178,
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
    ##  [1] forcats_0.5.0   stringr_1.4.0   dplyr_1.0.0     purrr_0.3.4    
    ##  [5] readr_1.3.1     tidyr_1.1.0     tibble_3.0.1    ggplot2_3.3.1  
    ##  [9] tidyverse_1.3.0 broom_0.5.6    
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] tidyselect_1.1.0 xfun_0.14        haven_2.3.1      lattice_0.20-41 
    ##  [5] colorspace_1.4-1 vctrs_0.3.1      generics_0.0.2   htmltools_0.4.0 
    ##  [9] yaml_2.2.1       blob_1.2.1       rlang_0.4.6      pillar_1.4.4    
    ## [13] glue_1.4.1       withr_2.2.0      DBI_1.1.0        dbplyr_1.4.4    
    ## [17] modelr_0.1.8     readxl_1.3.1     lifecycle_0.2.0  munsell_0.5.0   
    ## [21] gtable_0.3.0     cellranger_1.1.0 rvest_0.3.5      evaluate_0.14   
    ## [25] labeling_0.3     knitr_1.28       fansi_0.4.1      Rcpp_1.0.4.6    
    ## [29] scales_1.1.1     backports_1.1.7  jsonlite_1.7.0   farver_2.0.3    
    ## [33] fs_1.4.1         hms_0.5.3        digest_0.6.25    stringi_1.4.6   
    ## [37] grid_3.6.0       cli_2.0.2        tools_3.6.0      magrittr_1.5    
    ## [41] crayon_1.3.4     pkgconfig_2.0.3  ellipsis_0.3.1   xml2_1.3.2      
    ## [45] reprex_0.3.0     lubridate_1.7.9  assertthat_0.2.1 rmarkdown_2.2   
    ## [49] httr_1.4.1       rstudioapi_0.11  R6_2.4.1         nlme_3.1-148    
    ## [53] compiler_3.6.0
