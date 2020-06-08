

survival_wrangle <- function(
  cohort_tbl, #
  pool_tbl,    #
  event
){
  
  library(tidyverse)
  
  # store cohort_tbl as x
  
  x <- as_tibble(cohort_tbl)
  
  # store pool_tbl as y
  
  y <- as_tibble(pool_tbl)
  
  # event determines which var to select for analysis
  
  if (event == '>=15') {
    y <- y %>% select(
      id,
      greater_or_eq_15,
      last_va_week
    )
  } else if (event == '>=10') {
    y <- y %>% select(
      id,
      greater_or_eq_10,
      last_va_week
    )
  } else if (event == '<=15') {
    y <- y %>% select(
      id,
      greater_or_eq_neg_15,
      last_va_week
    )
  } else {
    print('Error: enter valid event argument.')
  }
  
  # standardised var across event arguments
  y <- y %>% rename(outcome_week = 2)
  
  # add censorship vars
  output <- left_join(
    x,
    y,
    by = 'id'
  )
  
  # create outcome var
  output <- output %>% 
    mutate(outcome = if_else(is.na(outcome_week), 0, 1))
  
  # create time var (coalesce)
  output <- output %>% 
    mutate(time = coalesce(outcome_week, last_va_week))


  
}

