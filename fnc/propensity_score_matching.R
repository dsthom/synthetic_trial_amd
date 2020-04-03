# function to generate n ps-matched sets
# input: abc (8 by 65) & ehr (8 by 4,472)
# output: 

# score abc Avastin arm

propensity_score_matching <- function(abc, ehr, iterations, caliper) {
  
  # set seed for reproducible sampling
  set.seed(1337)
  
  # source propensity model
  source("src/propensity_model.R")
  
  # predict Pr of treatment(Avastin == 1)
  abc.psm <- augment(x = propensity_model,
                           newdata = abc,
                           type.predict = "response") %>% 
    # rename .fitted and .se.fit
    rename(
      propensity_score = .fitted,
      propensity_score_se = .se.fit
    )
  
  # create a list of dataframes equal to iterations
  abc.psm <- rep(list(abc.psm), iterations)
  
  for(i in seq_along(abc.psm)) {
    abc.psm[[i]][["iteration"]] <-  i
  }
  
  abc.psm <- do.call(rbind.data.frame, abc.psm)
  
  abc.psm <- abc.psm %>% 
    group_by(iteration) %>% 
    nest()
  
  # shuffle order 
}
