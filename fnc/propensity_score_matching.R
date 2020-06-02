# function to generate n ps-matched sets
# input: abc (8 by 65) & ehr (8 by 4,472)
# output: 

propensity_score_matching <- function(
  trial_arm, # table of
  synthetic_arm, # table of
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
    newdata = synthetic_arm,
    type.predict = "response") %>% 
    # rename .fitted and .se.fit
    rename(
      propensity_score = .fitted,
      propensity_score_se = .se.fit
    )
  
  # calculate propensity_score width of 0.1 standard deviation

  caliper_ps <- sd(trial.psm$propensity_score[trial.psm$treatment == 'avastin'])
  caliper_ps <- caliper_ps * caliper

  # inexact matching
  ps.matches <- trial.psm %>% 
    # convert to list-column
    group_by(id) %>% 
    nest() %>% 
    # tibble of all exact ps matches
    mutate(matches = map(
      .x = data,
      ~ fuzzyjoin::difference_left_join(
        x = .x,
        y = synthetic.psm,
        by = "propensity_score",
        max_dist = caliper_ps 
      )
    )) %>% 
    # randomly sample 1 match for each trial eye
    mutate(sampled_match = map(
      .x = matches,
      ~ sample_n(
        .x,
        size = 1
      )
    )) %>% 
    # unnest list column
    select(sampled_match) %>% 
    unnest() %>% 
    ungroup() %>% 
    # rename ids
    rename(
      abc_id = id,
      ehr_id = id1
    ) %>% 
    # drop rows that have 0 matches
    drop_na(ehr_id)
  
  # create longform list of matched eyes for future filtering export a list in longform of matches and pair_id
  matched.pairs <- ps.matches %>% 
    select(
      abc = abc_id,
      ehr = ehr_id) %>% 
    mutate(pair_id = 1:nrow(ps.matches)) %>% 
    pivot_longer(
      cols = abc:ehr,
      names_to = "cohort",
      values_to = "id")
  
  # create output table ammenable for logistic regression
  # trial
  matched.trial <- trial.psm %>% 
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    # add pair_id
    left_join(select(matched.pairs, id, pair_id),
              by = "id")
  
  # synthetic
  matched.synthetic <- synthetic.psm %>% 
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    # add pair_id 
    left_join(select(matched.pairs, id, pair_id),
              by = "id")
  
  # combine tables into one
  output <- bind_rows(matched.trial, matched.synthetic) %>% 
    # rearrange row order
    select(id,
           treatment, 
           pair_id,
           propensity_score,
           age,
           gender,
           baseline_etdrs,
           drug_load,
           drug_recency,
           study_exit_va)
  
}