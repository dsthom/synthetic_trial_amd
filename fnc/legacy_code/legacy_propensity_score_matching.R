# function to generate n ps-matched sets
# input: abc (8 by 65) & ehr (8 by 4,472)
# output: 

propensity_score_matching <- function(trial, iterations) {
  
  # set seed for reproducible sampling
  set.seed(1337)
  
  # source propensity model
  source("src/propensity_model.R")
  
  # predict Pr of treatment(Avastin == 1) for trial arm
  trial.psm <- augment(
    x = propensity_model,
    newdata = trial,
    type.predict = "response") %>% 
    # rename .fitted and .se.fit
    rename(
      propensity_score = .fitted,
      propensity_score_se = .se.fit
    )
  
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
  
  trial.list 
}