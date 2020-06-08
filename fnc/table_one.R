
table_one <- function(
  cohort
) {
  
  output <- cohort %>% 
    group_by(treatment) %>% 
    summarise(
      female_n = sum(gender == 'F'),
      female_prop = round(sum(gender == 'F') / n(), 2),
      age_median = median(age),
      age_iqr = IQR(age),
      age_min = min(age),
      age_max = max(age),
      va_median = median(baseline_etdrs),
      va_iqr = IQR(baseline_etdrs),
      va_min = min(baseline_etdrs),
      va_max = max(baseline_etdrs)
    )
  
  print(output)
}