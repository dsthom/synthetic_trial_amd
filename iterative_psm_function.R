# function for iterative psm

library(tidyverse)

iterative_psm <- function(df, match_ratio, caliper_sd) {
  
  set.seed(1337)
  
  for (i in (df)){
    ps <- df %>% 
      sample_n(size = nrow(df),
               replace = FALSE)
    
    psm <- Matching::Match(Tr = ps$treatment[ps$match_counter == "0"], 
                           X = ps$propensity_score [ps$match_counter == "0"],
                           M = match_ratio, 
                           caliper = caliper_sd,
                           replace = FALSE,
                           ties = FALSE)
    
    matches <- ps[unlist(psm[c("index.treated", "index.control")]), ]
    
# update match_counter if matched
  }
  
  matches <- matches %>% 
    nest(iteration)
}

# input is list of ps X matches with a variatible itration (1 to 10)