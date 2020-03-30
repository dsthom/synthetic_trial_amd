# function to calculate the inverse probability of treatment
# input: abc (8 by 65) & ehr (8 by 4,472); output: ipt (*9* by 4,537)---additional column is ipt

#
ipt <- function(abc, ehr){
  
  # source propensity model
  source("src/propensity_model.R")
  
  # bind abc & ehr tables
  iptw <- bind_rows(abc, ehr)
  
  # predict probability of treatment
  iptw <- broom::augment(x = propensity_model,
                   newdata = iptw,
                   type.predict = "response") %>% 
    # calculate inverse probability of treatment weights
    mutate(iptw = 1 / .fitted)  
}