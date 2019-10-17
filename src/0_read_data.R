library(tidyverse)

abc <- read_csv("data/abc_trial_acuity.csv",
                col_types = cols(
                  studynumber = col_character(),
                  lost = col_factor(),
                  arm = col_factor(),
                  treatment = col_factor(),
                  trt = col_factor()
                ))

# Shorten variable names that start_with "vast"
abc <- abc %>% 
  rename_at(vars(starts_with("vast")), funs(str_replace(., "vast", "va_")))
            
# convert treatment strings to lower_case
abc <- abc %>% 
  mutate(treatment = tolower(treatment))
  
# restrict to those randomised to recieve avastin
abc <- abc %>% 
  filter(treatment = "avastin")

# tidy data using pivot_longer() or gather()
