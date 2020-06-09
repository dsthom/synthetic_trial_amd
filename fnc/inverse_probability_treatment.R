# function to calculate the inverse probability of treatment
# input: abc (8 by 65) & ehr (8 by 4,472)
# output: ipt (*9* by 4,537)---additional column is iptw

#
inverse_probability_treatment <- function(
  trial_arm, 
  synthetic_arm,
  ps_trimming){
  
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

