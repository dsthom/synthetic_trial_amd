# Script to preoprocess and run glm

# Output is list-column workflow with the exponeniated ORs of glm in tidy format

va_glm <- function(data) {
  
  # impute negative etdrs denoting light perception, counting fingers, etc., to 0
  data$study_exit_va[data$study_exit_va < 0] <- 0
  
  # calculate va_change and binary outcomes
  data <- data %>% 
    mutate(
      va_change = study_exit_va - baseline_etdrs,
      fifteen_gain = if_else(va_change >= 15, 1, 0),
      ten_gain = if_else(va_change >= 10, 1, 0),
      fifteen_loss = if_else(va_change > -15, 1, 0)) %>% 
    # make eylea reference level
    mutate(treatment = factor(treatment,
                              levels = c("eylea", "avastin"))) %>% 
    # pivot_longer
    pivot_longer(cols = fifteen_gain:fifteen_loss,
                 names_to = "outcome",
                 values_to = "y") %>% 
    # convert to list-column workflow
    group_by(outcome) %>% 
    nest()
    
  # list-column workflow
  data <- data %>% 
    # create column of contigency tables (n)
    mutate(n_table = map(.x = data,
               ~ table(.x$treatment, .x$y))) %>% 
    # create column of contingency tables (%)
    mutate(prop_table = map(.x = n_table,
                            ~ round(prop.table(.x), 2)))
  
  # glm
   data <- data %>%
     # fit a glm to each nested dataframe
     mutate(glm = map(
       .x = data,
       ~ glm(formula = y ~ treatment,
             family = binomial(link = "logit"),
             data = .x)
     )) %>% 
  # create column with tidy() output
    mutate(tidy_output = map(
      .x = glm,
      ~ broom::tidy(
        .x,
        conf.int = TRUE,
        conf.level = 0.95,
        exponentiate = TRUE)
    ))
   
  # repeat model and tidy output, adjsuting for drug_load
   data <- data %>% 
     # fit (adjusted) glm to each nested dataframe
     mutate(adj_glm = map(
       .x = data,
       ~ glm(formula = y ~ treatment + drug_load,
             family = binomial(link = "logit"),
             data = .x)
     )) %>% 
     # create column with tidy() output
     mutate(adj_tidy_output = map(
       .x = adj_glm,
       ~ broom::tidy(
         .x,
         conf.int = TRUE,
         conf.level = 0.95,
         exponentiate = TRUE)
     ))
}  