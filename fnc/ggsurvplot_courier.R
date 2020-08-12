# wrapper for survminer::ggsurvplot

ggsurvplot_courier <- function(
  fit,   # survfit object
  data,  # data used to model survfit object
  title = NULL
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
    palette = c("#0C7BDC", "#FFC20A"),
    
    # confidence intervals
    conf.int = TRUE,
    conf.int.style = 'ribbon',
    conf.int.alpha = 0.25,
    
    # censoring
    censor.shape = '|', 
    censor.size = 1,
    
    # axes
    break.time.by = 12,
    xlim = c(0, 54),
    xlab = 'Week',
    
    ylab = '% Pr(y = 0)',
    
    # legend
    legend = 'bottom',
    legend.title = "",
    legend.labs = c("Aflibercept", "Bevacizumab"),
    
    # annotations
    pval = TRUE,
    pval.size = 3,
    pval.coord = c(26, 96),
    
    # aesthetic
    ggtheme = courier_bw,
    font.family = 'Courier',
    
    # title
    
    title = title
  )
  
}