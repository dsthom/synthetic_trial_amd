Code review
================
01 July, 2020

## abc\_to\_kale.Rmd

`bed` has less NA values in `.$ETDRS` and has much less rows than
`abc.acuity`, indicating that it actually removes data after the merge

`abc.patient.details` contains 5 missing values in the trt column

## propensity\_model.R

Cannot find file abc\_patient\_details.csv, therefore the code review is
without really testing it. Instead of specifying all columns in `select`
for reordering, you could also use `everything()`

## 0\_cohorts\_generation.Rmd

small typos corrected.

Cannot find file abc\_patient\_details.csv, therefore the code review is
without really testing it.

## funcs

`exact_matching()` and `propensity_score_matching()` as far as I see,
you don’t match eye side (R/L)- correct ? `va_glm()` will only impute
the negative ETDRS for column `study_exit_va` in each data frame - hope
this is intended.

## 1\_exchangebility.Rmd

again, I cannot access the files, so purely code review without actually
running it.

The
    steps

    # add var to identify each cohort when lists are mergedInstead of assigning the
    # combine individual elements into a singl df

could posssibly be much simplified by using `bind_rows(list, .id =
"cohort")`

## 1\_noninferiority.Rmd

`impute_neg_etdrs()` will only impute the negative ETDRS for column
`study_exit_va` in each data frame - hope this is intended.

DId not know `purrr::pluck()`. Love it

## 1\_outcome\_regression.Rmd

`nc[[6]][[1]]` etc - this type of subsetting is maybe a bit dangerous.
Cannot check if this is actually getting the data subset that you are
specifying.

defining `estimands` - is there a good reason why this is not automated
and you have added a precomputed table?

## 1\_survival\_analysis.Rmd

For survival package, you need to make sure that the data only has one
row per observed ID. This is absolutely essential\!\! Otherwise it
messes up the entire function. I cannot open the files so cannot check
the data structure.

This is from within the definition of `survival_wrangle()`

    output <- output %>% 
        mutate(time = coalesce(outcome_week, last_va_week))

It suggests to me that there might be more than one row per ID.

I am personally not a big fan of the `ggsurvplot()` function. I have a
modified implementation of a kaplan meier geom in my github repository
`tjebo/ggsurv` This also gives an option to visualise an interval
censored model.

Admittedly, it is far from being perfect, and does not offer the
functionality of ggsurvplot, but I prefer it because you can stick to
normal ggplot2 syntax :)
