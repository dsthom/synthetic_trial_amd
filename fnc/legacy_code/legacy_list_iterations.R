# create n (specified in argument) shuffled trial datasets, each as an element in a list

list_iterations <- function(trial, synthetic, iterations) {
  
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
  
  # rename list elements
  
  iteration_seq <- seq(from = 1,
                       to = iterations)
  
  names(trial.list) <- str_c("interation_", iteration_seq)
  
  trial.list <- map(
    trial.list,
    ~ sample_n(
      .x,
      size = nrow(.x),
      replace = FALSE
    )) 
  
  # nest each element
  trial.list <- map(
    trial.list,
    ~ group_by(id)
  )
  map(
    .x,
    ~ group_by(id))
  
  trial.list
}