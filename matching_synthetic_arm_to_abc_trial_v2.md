matching\_synthetic\_arm\_to\_abc\_trial\_v2
================
Darren S Thomas
15 January, 2020

Like `matching_synthetic_arm_to_abc_trial.Rmd`, but the propensity
scoring is derived from a logistic regression fitted to abc data
(i.e. probability of sbeing randomised to recieve Avastin vs. SOC) and
then this model is used to calculate the ps of potential synthetic
controls.

# Setup

Load packages.

``` r
library(tidymodels)
library(tidyverse)
```

Assign default ggplot theme.

``` r
courier_bw <- theme_bw() +
  theme(text = element_text(family = "Courier"),
        legend.position = "bottom")

theme_set(courier_bw)
```

Read characteristics of abc subjects.

``` r
abc <- read_csv("data/abc_patient_characteristics.csv",
                    col_types = cols(
                      id = col_character())) %>% 
  mutate(cohort = "abc")
```

Assign a dummy variable as being 1 if randomised to recieve Avastin and
0 if Eylea recieved.

``` r
abc <- abc %>% 
  # create avastin_dummy that is 1 if avastin recieved and 0 if eylea
  mutate(avastin = if_else(treatment == "avastin", 1, 0)) %>% 
  rename(age = age_at_baseline,
         etdrs = baseline_etdrs)
```

# logit propensity scoring

Baseline characteristics were balanced between the ABC and EHR arms on
proensity scores derived from a logistic generalised linear model
regressed on treatment recieved (1 if randomised to recieve Avastin/ 0
if Eylea recieved as per standard healthcare). Baseline characteristics
contributing to the pronensity scores were `baseline_va`,
`age_at_baseline`, `gender` (*AND POTENTIALLY MATCHED FOR OCT THICKNESS
AND PED, IF AVAILABLE*).

``` r
logit <- glm(formula = avastin ~
               etdrs +
               age + 
               gender,
               family = binomial(link = "logit"),
             data = abc)
```

![](matching_synthetic_arm_to_abc_trial_v2_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

``` r
  augment(logit,
        data = abc,
        type.predict = "response") %>% 
  mutate(avastin = factor(avastin, levels = c(1, 0))) %>% 
  drop_na(treatment) %>% 
  ggplot(aes(x = .fitted, fill = avastin)) +
  geom_density(alpha = 0.75, size = 0) +
  labs(subtitle = "Distribution of propensity scores",
       x = "Propensity score",
       y = "Density") +
  scale_fill_discrete(name = NULL, labels = c("Avastin arm", "SOC arm")) +
  scale_x_continuous(breaks = seq(0, 1, 0.1),
                     limits = c(0, 1))
```

![](matching_synthetic_arm_to_abc_trial_v2_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

All ABC avastin arm subejcts and potential synthetical controls were
assigned a propensy score using our model trained on all ABC trial
subjects. The ps distributions among the Avastin arm and potential
synthetic controls were then plotted.

Read the baseline characteristics of potential synthetic controls whom
recieved Eylea & combine these into a single dataframe with the baseline
characteristics of those in the Avastin arm.

``` r
ehr <- read_csv("data/ehr_patient_characteristics.csv") %>% 
  mutate(cohort = "ehr") %>% 
  rename(age = age_at_baseline,
         etdrs = baseline_etdrs)

abc.ehr <- abc %>% 
  filter(treatment == "avastin") %>% 
  select(- avastin) %>% 
  bind_rows(ehr)
```

Using our ps model to assign ps on our new dataframe.

``` r
ps <- augment(logit,
        data = abc,
        newdata = abc.ehr,
        type.predict = "response") 

ps %>% 
  ggplot(aes(x = .fitted, fill = cohort)) +
  geom_density(alpha = 0.75, size = 0) +
  labs(subtitle = "Distribution of propensity scores",
       x = "Propensity score",
       y = "Density") +
  scale_fill_discrete(name = NULL, labels = c("ABC Avastin arm", "Potential synthetic controls")) +
  scale_x_continuous(breaks = seq(0, 1, 0.1),
                     limits = c(0, 1)) + 
  scale_y_continuous(limits = c(0, 4))
```

![](matching_synthetic_arm_to_abc_trial_v2_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

# singleplex psm

The *fundamental problem of causal inference* is that we know only the
factual and not counterfactual outcomes.

Tenets of causal inference:

  - independence—that the treatment assignment is independent of outcome
    (this we assume for RCTs)
  - strong ignorability (assumptions we must make for observation data)
    of I) unconfoundness (that treatment assignment and potential
    outcomes are independent of covariate attributes); and II) overlap
    ().

’Notice that NNM faces the risk of bad matches if the closest neighbor
is far away. This issue can be resolved by imposing a tolerance level on
the maximum distance,known as the caliper (see e.g., \[M. Lunt.
Selecting an appropriate caliper can be essential for achieving good
balance with propensity score matching. American journal of
epidemiology, 179(2):226–235, 2014.\]). There are some rules of thumb
for choosing the calipers (see e.g., \[M. Lunt. Selecting an appropriate
caliper can be essential for achieving good balance with propensity
score matching. American journal of epidemiology, 179(2):226–235,
2014.s\]).

Nearest neighbour matching OR within a specified caliper without
replacement using the ‘tidyverse’/SQL
\[<https://arxiv.org/pdf/1609.03540.pdf>\].

Try first with a caliper equal to 0.1 SD of ABC avastin propensity
score.\[see simulation study:
<https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3873103/#__ffn_sectitle>\]

``` r
sd(ps$.fitted[ps$treatment == 'avastin'])
```

    ## [1] 0.1022588

``` r
ps <- ps %>% 
  rename(propensity_score = .fitted) %>% 
  # add treatment dummmy variable
  mutate(treatment = if_else(treatment == "avastin", 1, 0)) %>% 
  # drop se.fit
  select(-.se.fit) %>% 
  mutate(match = "1")
```

``` r
# randomly shuffle data before submitting to function
ps <- ps %>% 
    sample_n(size = nrow(ps), # n must be equal to n_rows
             replace = FALSE)

# propensity score matching
psm <- Matching::Match(Tr = ps$treatment, # requires vectors
                       X = ps$propensity_score, # requires vectors
                       M = 1, # 1:1 matching
                       caliper = 0.1, # units are as SD
                       replace = FALSE,
                       ties = FALSE)

# retrieve output
matches <- ps[unlist(psm[c("index.treated", "index.control")]), ]
```

``` r
matches %>% 
  ggplot(aes(x = propensity_score)) +
  facet_grid(.~ cohort) +
  geom_histogram(alpha = 0.75, 
                 size = 0, 
                 fill = "#FF6666") +
  labs(subtitle = "Distribution of propensity scores after matching by propensity score",
       x = "Propensity score",
       y = "Density") +
  scale_x_continuous(breaks = seq(0, 1, 0.2),
                     limits = c(0, 1))
```

![](matching_synthetic_arm_to_abc_trial_v2_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->

# iterative matching with map

``` r
# add match_counter (1 if already matched/ 0 if unmatched)
ps <- ps %>% 
  mutate(match_counter = 0)

# create a list of 10 identical dataframes
iteration.list <- list()

for (i in 1:10){ # state n iterations
  iteration.list[[i]] <- ps %>% 
    # shuffle each iteration
    sample_n(size = nrow(ps),
             replace = FALSE)
  iteration.list[[i]][[11]] <-  i
}
```

``` r
# convert from list to list column
iteration.list.col <- do.call(rbind.data.frame, iteration.list)

iteration.list.col <- iteration.list.col %>% 
  rename(iteration = V11) %>% 
  group_by(iteration) %>% 
  nest()
```

``` r
psm_for_map <- function(.x, match_ratio, caliper_sd, seed){
   # set seed
  set.seed(seed)
  # match on psm
  psm <- Matching::Match(Tr = .x$treatment,
                         X = .x$propensity_score,
                         M = match_ratio, 
                         caliper = caliper_sd,
                         replace = FALSE,
                         ties = FALSE)
  # update match_counter if matched (ONLY FOR CONTROLS)
  
  #output
 .x[unlist(psm[c("index.treated", "index.control")]), ]
}
```

``` r
iteration.list.col <- iteration.list.col %>% 
  mutate(psm = map(.x = data, ~ psm_for_map(.x, 
                                            match_ratio = 1,
                                            caliper_sd = 0.1,
                                            seed = 1337)))
```

TO do: prevent matched controls being matched again during subsequent
iterations

# diagnostics

Calculate AUC for each iteration. AFTER MATCHING, AUC BETWEEN ABC & EHR
PS DISTRIBUTIONS SHOULD BE ~ 0.5. INDEED, COAVRIATES INCLDUED IN THE
PROPENSITY SCORE SHOIULD BE MATCHED.

``` r
iteration.list.col <- iteration.list.col %>% 
  mutate(auc = map(psm,
                       ~ roc_auc(.x,
                                 truth = factor(treatment),
                                 propensity_score)))
```

run other diagnostics (violin plot, box plot)

  - check the balance of ps, and each of the coavriates included in the
    ps model

CALCULATE ‘VARIANCE OF THE EFFECT ESTIATES’.

How many iterations can you run before AUC tails off? Plot iterations x
versus AUC on y.

Play around with the algortihms to find that which best balances
covariates/ps (use `Matching::MatchBalance`). `Matching` also has
`GenMatch`.

# Analysis (compare two Loess curves?)

Link va to cases and controls.

adjust for injection\_count in the analysis.