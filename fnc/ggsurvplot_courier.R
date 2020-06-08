# wrapper for survminer::ggsurvplot

ggsurvplot_courier <- function(
  fit, # survfit object
  data # data used to model survfit object
){
  
  # load dependencies
  library(tidyverse)
  library(survminer)
  
  # set default ggplot theme
  courier_bw <- theme_bw() +
    theme(text = element_text(family = "Courier"),
          legend.position = "bottom")
  
  theme_set(courier_bw)
  
  # set defaults
  
  ggsurvplot(
    fit = fit,
    data = data,
    fun = 'pct',
    conf.int = TRUE,
    conf.int.style = "ribbon",
    conf.int.alpha = 0.25,
    censor.shape = "|", 
    censor.size = 2,
    risk.table = 'percentage',
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
    legend.labs = c('Aflibercept', 'Bevacizumab'),
    xlab = 'Week',
    ylab = 'Cumulative event',
    surv.median.line = 'hv',
    pval = TRUE,
    pval.size = 4,
    pval.coord = c(48, 1),
    ggtheme = courier_bw
  )
  
}