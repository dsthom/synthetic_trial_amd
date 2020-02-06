
iteration_list <- function(df, iterations){

iteration.list <- list()

for (i in 1:iterations){ # state n iterations
  iteration.list[[i]] = ps %>% 
    # shuffle each iteration
    sample_n(size = nrow(ps), # n must be equal to n_rows
             replace = FALSE)  
  iteration.list[[i]][[10]] <-  i
}
}