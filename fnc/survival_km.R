
survival_km <- function(
  data
){
  
  library(survival)
  
  output <- survfit(
    formula = Surv(time, outcome) ~ treatment,
    data = data
  )
  
}