library(tidyverse)

# ------------------------------------------------------------------------------
# acuity
  
abc.acuity <- read_csv("data/abc_trial_acuity.csv",
                col_types = cols(
                  studynumber = col_character(),
                  lost = col_factor(),
                  arm = col_factor(),
                  treatment = col_factor(),
                  trt = col_factor()
                ))

# Shorten variable names that start_with "vast"
abc.acuity  <- abc.acuity  %>% 
  rename_at(vars(starts_with("vast")), funs(str_replace(., "vast", "va_")))

# Reorder va by chronology
abc.acuity  <- abc.acuity  %>% 
  select(abc_id = studynumber,
         lost,
         arm,
         treatment,
         trt,
         va_0,
         va_1,
         va_6,
         va_12,
         va_18,
         va_24,
         va_30,
         va_36,
         va_42,
         va_48,
         va_54)
            
# convert treatment strings to lower_case
abc.acuity  <- abc.acuity  %>% 
  mutate(treatment = tolower(treatment))
  
# restrict to those randomised to recieve avastin
abc.acuity  <- abc.acuity  %>% 
  filter(treatment == "avastin")

# tidy data using pivot_longer() or gather()
#. Perhaps unnecessary

# ------------------------------------------------------------------------------
# age
abc.age <- read_csv("data/abc_trial_age.csv",
                    col_types = cols(
                      studyNumber = col_character()
                    ))

abc.age <- abc.age %>% 
  select(abc_id = studyNumber,
         age = Age,
         avastin_n = avastintrt)


# merge dataframes
abc.arm <- abc.acuity %>% 
  left_join(abc.age,
            by = "abc_id",
            keep = FALSE)
