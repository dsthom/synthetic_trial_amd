# script coding the function for propensity_score_matching()

propensity_score_matching <- function(
  trial_arm, 
  synthetic_arm,
  iterations,
  caliper_sd){
  
  # set seed for reproduyble resamping/shuffling
  set.seed(1337)

  # 1. create list-column workflow
  
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
  
  # dulicate as caliper_ps to be sued to create a vector storing the caliepr to be sued for inexact matching
  caliper_ps <- trial.psm
  
  # create a list of trial dataframes equal to iterations
  trial.list <- rep(list(trial.psm), iterations)
  
  for(i in seq_along(trial.list)) {
    trial.list[[i]][["iteration"]] <-  i
  }
  
  # rename list elements 
  iteration_seq <- seq(from = 1,
                       to = iterations)
  
  names(trial.list) <- str_c("interation_", iteration_seq)
  
  # shuffle the order
  trial.list <- map(
    trial.list,
    ~ sample_n(
      .x,
      size = nrow(.x),
      replace = FALSE
    )) 
  
  # coerce to a single dataframe
  trial.list <- do.call(rbind.data.frame, trial.list)
  
  # convert to list-column
  trial.list <- trial.list %>% 
    group_by(iteration, id) %>% 
    nest()
  
  # 2. calculate propensity_score width of 0.1 standard deviation
  caliper_ps <- (sd(caliper_ps$propensity_score) * caliper_sd) 
  
  # 3. loop fuzzy_left_join
  
    # calculate Pr treatment(Avastin == 1 | L) for synthetic arm
    synthetic_arm <- augment(
      x = propensity_model,
      newdata = synthetic_arm,
      type.predict = "response") %>% 
      # rename .fitted and .se.fit
      rename(
        propensity_score = .fitted,
        propensity_score_se = .se.fit
      )  %>% 
      # create a match_counter that is upated to 1 if matched 
      mutate(match_counter = 0) %>% ###!!!
      # shuffle order
      sample_n(
        size = nrow(synthetic_arm),
        replace = FALSE)
    
    # loop over with inaxact matching, smapling one match
    trial.list <- trial.list %>% 
      mutate(matchee = map(
        .x = data,
        ~ sample_n(
            fuzzyjoin::difference_left_join(
            x = .x,
            y = synthetic_arm,
            by = "propensity_score",
            max_dist = caliper_ps
        ),
        size = 1)
      )) 
      
  # 4. unnest, convert to longform
      trial.list <- trial.list %>% 
        # reset groupings
        unnest() %>% 
        ungroup() %>% 
        # nest by iteration
        group_by(iteration) %>% 
        nest()
        
     # add pair_id map() left_join, drop match_counter(), stack, union
    
      #       group_by(iteration) %>% nest()
      
  
}