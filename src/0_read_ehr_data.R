# remove all exclusion criteria; restrict to those who recieved Eylea.
library(tidyverse)

# baseline covariates for psm

ehr <- read_csv("data/20200106_ehr.csv")
  
ehr <- ehr %>% 
  # restrict to eyes recieving eylea
  filter(no_eylea_excl == 0) %>% 
  # restrict to index eyes
  filter(index_eye == 1) %>% 
  # exclude eyes that ever recieved stereotactic radiotherapy, thermotherapy or photodyanic therapy before baseline 
  filter(radio_thermo_excl == 0) %>% 
  # exclude eyes that recieved verteporfin within 7 days of baseline
  filter(verteporfin_thermo_excl == 0) %>% 
  # exclude eyes that ever recieved Macugen, Avastin or Lucentits before baseline clinicaltrial
  filter(clinical_trial_excl == 0) %>% 
  # exclude eyes that ever recieved intravitreal implants before baseline
  filter(intravitreal_excl == 0) %>% 
  # exclude eyes that ever recieved recieved vitrectomy before baseline
  filter(vitrectomy_excl == 0) %>% 
  # exclude eyes ever diagnosed with diabetic retinopathy before baseline
  filter(diabetic_retinopathy_excl == 0) %>% 
  # exclude eyes ever diagnosed with rvo before baseline
  filter(rvo_excl == 0) %>% 
  # exclude eyes ever diagnosed with glaucoma before baseline
  filter(glaucoma_excl == 0) %>% 
  # exclude eyes that ever had corneal surgery
  filter(corneal_transplant_excl == 0) %>% 
  # exclude eyes that switched to Avastin or Lucentis during the study period
  filter(switch_excl == 0) %>% 
  # add treatment variable
  mutate(treatment = "eylea") %>% 
  # select relavant variables
  select(id = patient_eye,
         treatment,
         injection_count,
         gender,
         age_at_baseline,
         baseline_etdrs = baseline_va) %>% 
  # drop eyes that have missing gender, age_at_baseline or baseline_etdrs
  drop_na(gender, age_at_baseline, baseline_etdrs)

ehr %>% 
write_csv("data/ehr_patient_characteristics.csv")

# ehr va measurements
