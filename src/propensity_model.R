# Script to fit propensity score model, which will be sourced for iptw and psm

# load dependencies
library(broom)
library(tidyverse)

# read data locally 

abc.all <- read_csv("../data/abc_patient_details.csv",
                           col_types = cols(
                             id = col_character(),
                             age_at_baseline = col_integer(),
                             baseline_etdrs = col_integer(),
                             injection_count = col_integer(),
                             drug_recency = col_integer(),
                             study_exit_va = col_integer()
                           )) %>% 
  rename(
    age = age_at_baseline,
    drug_load = injection_count) %>% 
  # reorder
  select(
    id,
    treatment, 
    age, 
    gender,
    baseline_etdrs,
    drug_load,
    drug_recency,
    study_exit_va) %>% 
  # create dummy variable for treatment
  mutate(avastin = if_else(treatment != "avastin" | is.na(treatment), 0, 1))

# fit propensity model

propensity_model <- glm(avastin ~
                          age +
                          gender + 
                          baseline_etdrs,
                        family = binomial(link = "logit"),
                        data = abc.all)