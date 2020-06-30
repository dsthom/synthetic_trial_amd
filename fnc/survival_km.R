
survival_km <- function(
  data,
  weights # must be supplied in the tbl
){
  
  library(survival)
  
  output <- survfit(
    formula = Surv(time, outcome) ~ treatment,
    data = data,
    weights = weights
  )
  
}