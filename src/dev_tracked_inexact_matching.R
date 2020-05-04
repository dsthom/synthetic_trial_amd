# tracked_inexact_matching 
tracked_inexact_matching <- function()
{
  temp <- 
    # inexact matching
    sample_n(
      fuzzyjoin::difference_left_join(),
      size = 1) 
  
  # UPDATE MATCH COUNTER ###!!!
  synthetic_arm$match_counter[synthetic_arm$id %in% temp$id] <- 1
  # output
  temp
}