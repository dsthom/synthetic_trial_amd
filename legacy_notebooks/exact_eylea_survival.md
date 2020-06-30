exact\_matching\_eylea
================
Darren S Thomas
25 February, 2020

# Setup

Script to for time-to-event analysis. Requires
`src/synthetic_eylea_exact_survival.sql` to be run beforehand.

Load frequently used packages.

``` r
library(survival)
library(survminer)
library(tidyverse)
```

Set new default ggplot theme.

``` r
courier_bw <- theme_bw() +
  theme(text = element_text(family = "Courier"),
        legend.position = "bottom")

theme_set(courier_bw)
```

# Import from kale

Setup mysql connection.

``` r
kale <- DBI::dbConnect(RMySQL::MySQL(),
                        user = "admin", 
                        password = "password",
                        dbname = "NOVA6",
                        host = "127.0.0.1",
                        port = 9999)
```

Export table into r.

``` sql
SELECT *
FROM synthetic_eylea_exact_survival;
```

Convert to tibble and then nest.

``` r
eylea.exact.survival <- eylea.exact.survival %>% 
  as.tibble() %>% 
  group_by(event) %>% 
  nest() 
```

Model Kaplan-Meier for each event analysis.

``` r
eylea.exact.survival <- eylea.exact.survival %>% 
  mutate(km_models = map(
    .x = data,
    ~ survfit(Surv(time = week_exit,
                   event = outcome) ~ drug,
              data = .x)
  ))
```

ggsurvplot

``` r
eylea.exact.survival <- eylea.exact.survival %>% 
  mutate(
    plotz = 
      map2(.x = km_models,
           .y = data,
           ~ ggsurvplot(
              fit = .x,
              data = .y,
              fun = "event",
              conf.int = TRUE,
              conf.int.style = "ribbon",
              conf.int.alpha = 0.25,
              censor.shape = "|",
              risk.table = TRUE,
              tables.height = 0.2,
              fontsize = 3,
              risk.table.title = "Sample n",
              tables.theme = theme_cleantable(),
              tables.y.text = FALSE,
              font.family = "Courier",
              break.time.by = 6,
              xlim = c(0, 54),
              ylim = c(0, 1),
              title = "Kaplan-Meier", # pmap
              legend.title = "",
              legend.labs = c("Avastin", "Eylea"),
              xlab = "Week",
              ylab = "Cumulative event",
              surv.median.line = "hv",
              pval = TRUE,
              pval.size = 4,
              pval.coord = c(48, 1),
              ggtheme = courier_bw
           )))
```

to do:

  - pmap so third parameter is the event as title (15 letetrs gain,
    etc.)
  - cowplot/patchwork intpo one (preferably with one
legend)

<!-- end list -->

``` r
walk(eylea.exact.survival[["plotz"]], print)
```

![](exact_eylea_survival_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->![](exact_eylea_survival_files/figure-gfm/unnamed-chunk-8-2.png)<!-- -->![](exact_eylea_survival_files/figure-gfm/unnamed-chunk-8-3.png)<!-- -->
