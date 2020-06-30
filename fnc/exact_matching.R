# script for exact_matching

exact_matching <- function(
  trial_arm, # tbl of trial arm 
  synthetic_arm # tbl of synthetic pool
  ){
  
  # prep abc tibble
  trial_arm.em <- trial_arm %>% 
    
    # gender as binary numeric
    mutate(gender_m = if_else(gender == "M", 1, 0)) %>% 
    
    # merge confounders into a single variable for matching
    unite(
      col = "age_gender_etdrs",
      c("age", "gender", "baseline_etdrs"),
      sep = "-",
      remove = FALSE)
  
  # prep ehr tibble
  synthetic_arm.em <- synthetic_arm %>% 
    mutate(gender_m = if_else(gender == "M", 1, 0))
  
  # exact matching algorithm
  set.seed(1337)
  
  exact.matches <- trial_arm.em %>% 
    
    # convert to list-column
    group_by(id, age_gender_etdrs) %>% 
    nest() %>% 
    
    # tibble of all exact matches for each abc eye
    mutate(matches = map(.x = data,
                         ~ left_join(.x,
                                     synthetic_arm.em,
                                     by = c("age",
                                            "gender_m",
                                            "baseline_etdrs"),
                                     keep = TRUE))) %>% 
    
    # randomly sample 1 match for each trial eye
    mutate(sampled_match = map(
      .x = matches,
      ~ sample_n(
        .x, 
        size = 1))) %>% 
    
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
  matched.pairs <- exact.matches %>% 
    select(age_gender_etdrs,
           abc = abc_id,
           ehr = ehr_id) %>% 
    mutate(pair_id = 1:nrow(exact.matches)) %>% 
    pivot_longer(
      cols = abc:ehr,
      names_to = "cohort",
      values_to = "id")
  
  # create output table ammenable for logistic regression
  
  # trial
  matched.trial <- trial_arm.em %>% 
    
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    
    # add pair_id
    left_join(select(matched.pairs, id, pair_id),
              by = "id") %>% 
    
    # drop variable
    select(- age_gender_etdrs)
  
  # synthetic
  matched.ehr <- synthetic_arm.em %>% 
    
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    
    # add pair_id 
    left_join(select(matched.pairs, id, pair_id),
              by = "id")
  
  # combine tables into one
  output <- bind_rows(matched.trial, matched.ehr) %>% 
    # rearrange row order
    select(
      id,
      treatment, 
      pair_id,
      age,
      gender,
      baseline_etdrs,
      drug_load,
      drug_recency,
      study_exit_va)
}