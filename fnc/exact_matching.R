# script coding the function for exact_matching

# Requires table called abc from abc_patient_details of: id, treatment, age, gender, baseline_etdrs, drug_load, drug_load; and
#          table ehr from amd_synthetic_eylea_arm_study_table of: id, treatment, age, gender, baseline_etdrs, drug_load, drug_load

exact_matching <- function(abc, ehr){
  
  # prep abc tibble
  abc.em <- abc %>% 
    # gender as binary numeric
    mutate(gender_m = if_else(gender == "M", 1, 0)) %>% 
    # merge confounders into a single variable for matching
    unite(col = "age_gender_etdrs",
          c("age", "gender", "baseline_etdrs"),
          sep = "-",
          remove = FALSE)
  
  # prep ehr tibble
  ehr.em <- ehr %>% 
    mutate(gender_m = if_else(gender == "M", 1, 0))
  
  # exact matching algorithm
  set.seed(1337)
  
  exact.matches <- abc.em %>% 
    # convert to list-column
    group_by(id, age_gender_etdrs) %>% 
    nest() %>% 
    # tibble of all exact matches for each abc eye
    mutate(matches = map(.x = data,
                         ~ left_join(.x,
                                     ehr.em,
                                     by = c("age",
                                            "gender_m",
                                            "baseline_etdrs"),
                                     keep = TRUE))) %>% 
    # randomly sample 1 match for each abc eye
    mutate(sampled_match = map(.x = matches,
                               ~ sample_n(.x, size = 1))) %>% 
    # unnest list column
    select(sampled_match) %>% 
    unnest() %>% 
    ungroup() %>% 
    # rename ids
    rename(
      abc_id = id,
      ehr_id = id1
    ) %>% 
   # drop rows which have 0 matches
    drop_na(ehr_id)
  
  # create longform list of matched eyes for future filtering export a list in longform of matches and pair_id
  matched.pairs <- exact.matches %>% 
    select(age_gender_etdrs,
           abc = abc_id,
           ehr = ehr_id) %>% 
    mutate(pair_id = 1:nrow(exact.matches)) %>% 
    pivot_longer(cols = abc:ehr,
                 names_to = "cohort",
                 values_to = "id")
  
  # export matched.pairs to .csv for future reference
  write_csv(matched.pairs, "data/eylea_em_matches.csv")
  
  # create output table ammenable for logistic regression
  # abc
  matched.abc <- abc.em %>% 
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    # add pair_id
    left_join(select(matched.pairs, id, pair_id),
              by = "id") %>% 
    # drop variable
    select(- age_gender_etdrs)
  
  # ehr
  matched.ehr <- ehr.em %>% 
    # filter for only eyes that were matched
    filter(id %in% matched.pairs$id) %>% 
    # add pair_id 
    left_join(select(matched.pairs, id, pair_id),
              by = "id")
  
  # combine tables into one
  output <- bind_rows(matched.abc, matched.ehr) %>% 
    # rearrange row order
    select(id,
           treatment, 
           pair_id,
           age,
           gender,
           baseline_etdrs,
           drug_load,
           drug_recency,
           study_exit_va)
}