###!!!
fuzzy_left_join_without_replacement <- function(
  trial.list.column,
  synthetic, 
  matchee_vector, ###!!!
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
    # shuffle order
    sample_n(
      size = nrow(synthetic),
      replace = FALSE) %>% 
    # remove already matched
    filter(!id %in% matchee_vector) ###!!!
  
  # join within caliper
  temp <- fuzzyjoin::difference_left_join(
    x = trial.list.column,
    y = synthetic.psm,
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
      propensity_score = propensity_score.y
    )  
  
  # randomly sample one match
  
  matchee <- temp[1, ]
  
  # add matchee to global matchee_vector ###!!!
  matchee_vector <- c(matchee_vector, matchee$id) ###!!!
  
  # print output 
  matchee # change to matchee
  
}