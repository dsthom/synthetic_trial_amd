# function to generate n ps-matched sets
# input: abc (8 by 65) & ehr (8 by 4,472)
# output: 

propensity_score_matching <- function(
  trial_arm, 
  synthetic, 
  iterations, 
  caliper) {
  
  # set seed for reproducible sampling
  set.seed(1337)
  
  # source propensity model
  source("src/propensity_model.R")
  
  # predict Pr of treatment(Avastin == 1) for trial arm
  trial.psm <- augment(
    x = propensity_model,
    newdata = trial_arm,
    type.predict = "response") %>% 
    # rename .fitted and .se.fit
    rename(
      propensity_score = .fitted,
      propensity_score_se = .se.fit
    )
  
  # predict Pr of treatment(Avastin == 1) for synthetic arm
  synthetic.psm <- augment(
    x = propensity_model,
    newdata = synthetic,
    type.predict = "response") %>% 
    # rename .fitted and .se.fit
    rename(
      propensity_score = .fitted,
      propensity_score_se = .se.fit
    )  %>% 
    # create a match_counter that is upated to 1 if matched
    mutate(match_counter = 0)
  
  # create a list of trial dataframes equal to iterations
  trial.list <- rep(list(trial.psm), iterations)
  
  for(i in seq_along(trial.list)) {
    trial.list[[i]][["iteration"]] <-  i
  }
  
  trial.list <- do.call(rbind.data.frame, trial.list)
  
  # convert to list-column
  trial.list <- trial.list %>% 
    group_by(iteration) %>% 
    nest() %>% 
    mutate(data = map(
      .x = data,
      ~ sample_n(
        .x,
        size = nrow(.x),
        replace = FALSE
      )
    ))
  
  # in-exact matching
  
  ## calculate propensity_score width of 0.1 standard deviation
  caliper_ps <- trial.psm %>% 
    filter(treatment == 'avastin') %>% 
    summarise(caliper = sd(propensity_score))   ###!!! multiply by 0.1/caliper argument variable
    
  trial.list <- trial.list %>% 
    mutate(matches = map(
      .x = data,
      ~ fuzzyjoin::difference_left_join(
        x = .x,
        y = synthetic.psm,
        by = "propensity_score",
        max_dist = caliper_ps
      )
    ))
}