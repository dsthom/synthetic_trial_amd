outcome\_regression
================
Darren S Thomas
29 June, 2020

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

# extract each elelment of list as tbl
nc <- z %>% pluck("nc")

iptw <- z %>% pluck("iptw")
  
em <- z %>% pluck("em")

psm <- z %>% pluck("psm")
```

# source\_fncs

``` r
# source code to pre-process, run, and post-process glm (for em + psm)
source("../fnc/va_glm.R")
```

# nc

``` r
nc <- nc %>% 
  # add null weights
  mutate(weights = 1) %>% 
  va_glm()
```

``` r
# ≥ 15 letters
nc[[6]][[1]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.318    0.0354    -32.4  6.11e-230    0.297     0.341
    ## 2 treatmentavastin    1.50     0.268       1.51 1.30e-  1    0.871     2.50

``` r
# ≥ 10 letetrs 
nc[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.585    0.0314    -17.1  1.30e-65    0.550     0.622
    ## 2 treatmentavastin    1.47     0.251       1.52 1.27e- 1    0.892     2.39

``` r
# > -15 letters
nc[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          8.21    0.0486    43.3     0        7.47       9.04
    ## 2 treatmentavastin     1.20    0.431      0.418   0.676    0.558      3.12

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
    ## 1 (Intercept)         0.304    0.0255    -46.7   0         0.289     0.319
    ## 2 treatmentavastin    1.41     0.192       1.78  0.0755    0.956     2.03

``` r
# ≥ 10 letetrs 
iptw[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic   p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.561    0.0225    -25.8  3.14e-146    0.537     0.586
    ## 2 treatmentavastin    1.45     0.177       2.10 3.53e-  2    1.02      2.05

``` r
# > -15 letters
iptw[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          7.90    0.0341    60.6     0        7.40       8.45
    ## 2 treatmentavastin     1.21    0.300      0.631   0.528    0.699      2.29

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
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          0.20     0.414     -3.89 0.000101   0.0814     0.423
    ## 2 treatmentavastin     2.24     0.532      1.52 0.129      0.808      6.66

``` r
# ≥ 10 letetrs 
em[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          0.5      0.327    -2.12   0.0342    0.256     0.933
    ## 2 treatmentavastin     1.36     0.454     0.678  0.498     0.560     3.35

``` r
# > -15 letters
em[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic  p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>    <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)          3.67     0.376     3.46  0.000550    1.83       8.15
    ## 2 treatmentavastin     1.64     0.580     0.850 0.395       0.532      5.35

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
    ## 1 (Intercept)         0.477     0.265 -2.79e+ 0 0.00529    0.278     0.792
    ## 2 treatmentavastin    1.00      0.375 -2.22e-15 1.00       0.478     2.09

``` r
# ≥ 10 letters 
psm[[6]][[2]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)         0.711     0.252    -1.36    0.175    0.430      1.16
    ## 2 treatmentavastin    1.21      0.354     0.530   0.596    0.603      2.42

``` r
# > -15 letters
psm[[6]][[3]]
```

    ## # A tibble: 2 x 7
    ##   term             estimate std.error statistic     p.value conf.low conf.high
    ##   <chr>               <dbl>     <dbl>     <dbl>       <dbl>    <dbl>     <dbl>
    ## 1 (Intercept)        15.2       0.516     5.28  0.000000130    6.29      50.2 
    ## 2 treatmentavastin    0.645     0.671    -0.654 0.513          0.158      2.37

# forest\_plot

``` r
# set default ggplot theme
courier_bw <- theme_classic() +
  theme(text = element_text(family = "Courier"),
        legend.position = "bottom",
        axis.text.y = element_text(
          face = "bold", 
          size = 14,
          hjust = 0.5),
        axis.ticks = element_blank(),
        axis.line.y = element_blank())

theme_set(courier_bw)
```

``` r
#  read data
estimands <- tribble(
  ~method, ~outcome,        ~or,  ~lo95, ~hi95, ~p_value,
  'NC',    '≥ 15 letters',  1.50, 0.87,  2.50,  0.130,
  'IPTW',  '≥ 15 letters',  1.41, 0.96,  2.03,  0.076,
  'EM',    '≥ 15 letters',  2.24, 0.81,  6.66,  0.129,
  'PSM',   '≥ 15 letters',  0.98, 0.47,  2.05,  0.951,
  'NC',    '≥ 10 letters',  1.47, 0.89,  2.39,  0.127,
  'IPTW',  '≥ 10 letters',  1.45, 1.02,  2.05,  0.035,
  'EM',    '≥ 10 letters',  1.36, 0.56,  3.35,  0.498,
  'PSM',   '≥ 10 letters',  1.17, 0.59,  2.36,  0.650,
  'NC',    '> -15 letters', 1.20, 0.56,  3.12,  0.676,
  'IPTW',  '> -15 letters', 1.21, 0.70,  2.29,  0.528,
  'EM',    '> -15 letters', 1.64, 0.53,  5.35,  0.395,
  'PSM',   '> -15 letters', 0.66, 0.16,  2.41,  0.529
)
```

``` r
# plot, faceted by adjustment
estimands %>% 
  mutate(
    method = factor(method, levels = c("PSM", "EM", "IPTW", "NC")),
    outcome = factor(outcome, levels = c('≥ 15 letters', '≥ 10 letters', '> -15 letters'))) %>% 
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
    label = paste(or, " (", lo95, "-", hi95, ")",
                  sep = "")),
    parse = TRUE,
    nudge_y = -0.2) +
  # ammend visuals
  labs(
    x = "Odds Ratio (95% Confidence Interval)",
    y = NULL) +
  theme(legend.position = "none")
```

![](1_outcome_regression_files/figure-gfm/unnamed-chunk-21-1.png)<!-- -->

``` r
# export as .tiff
ggsave(
  filename = "fig_4.tiff",
  plot = last_plot(),
  device = "tiff",
  path = "../figs",
  width = 178,
  height = 100,
  units = "mm",
  dpi = 300
)
```
