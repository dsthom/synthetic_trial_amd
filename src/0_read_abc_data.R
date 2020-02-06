# script to transform original .csv files

library(tidyverse)

# ------------------------------------------------------------------------------
# acuity
  
abc.acuity <- read_csv("data/abc_trial_acuity.csv",
                col_types = cols(
                  studynumber = col_integer(),
                  lost = col_factor(),
                  arm = col_factor(),
                  treatment = col_factor(),
                  trt = col_factor()
                ))

abc.acuity  <- abc.acuity  %>% 
  # shorten variable names that start_with "vast"
  rename_at(vars(starts_with("vast")), funs(str_replace(., "vast", ""))) %>% 
  # convert treatment strings to lowercase 
  mutate(treatment = tolower(treatment)) %>% 
  # convert dataframe to long-form
  pivot_longer(cols = 2:12,
               names_to = "week",
               values_to = "etdrs") %>% 
  # arrange by studynumber & then week
  arrange(studynumber, week) %>% 
  # rename studynumber to snake_case 
  rename(study_number = studynumber)

write_csv(abc.acuity, "data/abc_va_longform.csv")

# ------------------------------------------------------------------------------
# baseline visual acuity

baseline.acuity <- abc.acuity %>% 
  filter(week == 0)

# ------------------------------------------------------------------------------
# age

abc.age <- read_csv("data/abc_trial_age.csv",
                    col_types = cols(
                      studyNumber = col_integer()
                    ))

abc.age <- abc.age %>% 
  # rename variables to lowercase
  rename(study_number = studyNumber,
         age_at_baseline = Age,
         injection_count = avastintrt) %>% 
  # convert Gender strings to M & F in parity with ehr data
  mutate(gender = case_when(gender == "Male" ~ "M",
                            gender == "Female" ~ "F")) %>% 
  # convert treatment strings to lowercase 
  mutate(treatment = tolower(treatment)) %>% 
  # append baseline va
  left_join(select(baseline.acuity, 
                   study_number, 
                   baseline_etdrs = etdrs),
            by = "study_number",
            keep = FALSE) %>% 
  # transform study_number to character
  mutate(study_number = as.character(study_number)) %>% 
  # keep only variables relevant to PS
  select(id = study_number,
         treatment,
         injection_count,
         gender,
         age_at_baseline,
         baseline_etdrs)

write_csv(abc.age, "data/abc_patient_characteristics.csv")
 