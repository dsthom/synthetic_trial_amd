###!!!
fuzzy_left_join_without_replacement <- function(
  trial.list.column,
  synthetic, 
  caliper) {
  
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
    mutate(match_counter = 0) %>% 
    # shuffle order
    sample_n(
      size = nrow(synthetic),
      replace = FALSE)
  
  # remove/mark matched synthetic controls (starts counting after first loop)
  
  synthetic.psm$match_counter[synthetic.psm$id %in% matchee$id] <- 1 ## update counter needs to be at top
  
  # join within caliper
  temp <- fuzzyjoin::difference_left_join(
    x = trial.list.column,
    y = filter(
      synthetic.psm,
      match_counter == 0),
    by = "propensity_score",
    max_dist = caliper_ps
  )  %>% 
    # discard abc columns and rename ehr columns
    select(
      id,
      treatment = treatment.y,
      age = age.y,
      gender = gender.y,
      baseline_etdrs = baseline_etdrs.y,
      drug_load = drug_load.y,
      propensity_score = propensity_score.y,
      match_counter
    )  
  
  
  # randomly sample one match
 
  matchee <- temp[1, ]
  
  # print output
  synthetic.psm
  
}