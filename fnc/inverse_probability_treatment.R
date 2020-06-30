# script to calculate the inverse probability of treatment

#
inverse_probability_treatment <- function(
  trial_arm, # tbl of trial arm
  synthetic_arm, # tbl of synthetic pool
  ps_trimming # boolean operator indicating whether trimming of ps should be undertaken
  ) {
  
  # source propensity model
  source("src/propensity_model.R")
  
  # bind trial & synthetic arms tables
  target.trial <- bind_rows(trial_arm, synthetic_arm)
  
  # predict Pr of treatment(Avastin == 1)
  output <- augment(x = propensity_model,
                  newdata = target.trial,
                  type.predict = "response") %>% 
    
    # calculate inverse probability of treatment weights
    mutate(ipw = 1 / .fitted)
  
  if(ps_trimming == TRUE){
    output <- output %>% 
      filter(between(
        ipw,
        min(output$ipw[output$treatment == 'avastin']),
        max(output$ipw[output$treatment == 'avastin'])
      ))
  }
  
  output
  
}