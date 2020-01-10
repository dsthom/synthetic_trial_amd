# Function to
 # see https://tidymodels.github.io/rsample/articles/Applications/Nested_Resampling.html

output <- structure(list(va_0 = numeric(0), 
                         va_1 = numeric(0), 
                         va_6 = numeric(0), 
                         va_12 = numeric(0), 
                         va_18 = numeric(0), 
                         va_24 = numeric(0),
                         va_30 = numeric(0),
                         va_36 = numeric(0), 
                         va_42 = numeric(0), 
                         va_48 = numeric(0), 
                         va_54 = numeric(0), 
                         age = numeric(0), 
                         avastin_n = numeric(0),
                         matched_abc_id = numeric(0)), 
                    row.names = integer(0), 
                    class = c("tbl_df", "tbl", "data.frame"))  # output as list of bootstrap datasets that can be parsed to purr for analysis
match_to_control <- function(control_pool, # required
                             case_pool, # required
                             criteria_1, # required
                             criteria_2, # optional
                             criteria_3, # optional
                             bootstrap_iterations = 1,
                             seed = 123) {
  set.seed(seed)
  for(i in seq_len(abc.arm)){
    # filter then union query? 
  }
  
  print(output) #
}

output <- vector("double", ncol(mtcars)) # output
for(i in seq_along(mtcars)) { # sequence
  output[[i]] <- median(mtcars[[i]], na.rm = TRUE) # body
}
output

# create function analysis the data.
bootstrap_time_to_event <- function() {
  
}

# example parsing of 
output %>% 
  purrr:map(.f = bootstrap_time_to_event)
puur::map(.x = )