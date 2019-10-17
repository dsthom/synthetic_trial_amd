set.seed

match_to_control <- function(control_pool, # required
                             case_pool, # required
                             criteria_1, # required
                             criteria_2, # optional
                             criteria_3, # optional
                             bootstrap_iterations = 1,
                             seed = 123) {
  set.seed(seed)
}