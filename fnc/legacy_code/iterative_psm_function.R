# function for iterative psm
# input is list of propensity scores

library(tidyverse)

output <- list()

iterative_psm <- function(list, match_ratio, caliper_sd, baseline_seed) {
  
  set.seed(baseline_seed)
  
  for (i in seq_along(list)){
    # filter for unmatched
    iteration.list[[i]] <- iteration.list[[i]] %>% 
      filter(match_counter == 0) %>% 
    # shuffle order
      sample_n(size = nrow(ps), # n must be equal to n_rows
               replace = FALSE)  
    # match on propensity score
    output[[i]] <- Matching::Match(Tr = iteration.list[[i]]$treatment,
                                   X = iteration.list[[i]]$propensity_score,
                                   M = match_ratio, 
                                   caliper = caliper_sd,
                                   replace = FALSE,
                                   ties = FALSE)
    # update match_counter if matched
    
    # set new seed
    set.seed(baseline_seed + i)
  }
  output
}