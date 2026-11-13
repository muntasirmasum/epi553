# Spring 2026 data code, copied verbatim from MLR_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

# ── Recode and clean ──────────────────────────────────────────────────────────
brfss_mlr <- brfss_full %>%
  mutate(
    # Outcome: mentally unhealthy days in past 30 (88 = none = 0; 77/99 = DK/refused = NA)
    menthlth_days = case_when(
      menthlth == 88              ~ 0,
      menthlth >= 1 & menthlth <= 30 ~ as.numeric(menthlth),
      TRUE                        ~ NA_real_
    ),
    # Physical health days (key predictor)
    physhlth_days = case_when(
      physhlth == 88              ~ 0,
      physhlth >= 1 & physhlth <= 30 ~ as.numeric(physhlth),
      TRUE                        ~ NA_real_
    ),
    # Sleep hours (practical cap at 14)
    sleep_hrs = case_when(
      sleptim1 >= 1 & sleptim1 <= 14 ~ as.numeric(sleptim1),
      TRUE                        ~ NA_real_
    ),
    # Age (capped at 80 per BRFSS coding)
    age = age80,
    # Income category (ordinal 1–8)
    income_cat = case_when(
      income2 %in% 1:8 ~ as.numeric(income2),
      TRUE             ~ NA_real_
    ),
    # Sex
    sex = factor(sexvar, levels = c(1, 2), labels = c("Male", "Female")),
    # Exercise in past 30 days (any physical activity)
    exercise = factor(case_when(
      exerany2 == 1 ~ "Yes",
      exerany2 == 2 ~ "No",
      TRUE          ~ NA_character_
    ), levels = c("No", "Yes")),
    # BMI (stored as integer × 100 in BRFSS)
    bmi = ifelse(bmi5 > 0, bmi5 / 100, NA_real_),
    # Income as labeled factor (for display)
    income_f = factor(income2, levels = 1:8,
      labels = c("<$10k", "$10-15k", "$15-20k", "$20-25k",
                 "$25-35k", "$35-50k", "$50-75k", ">$75k"))
  ) %>%
  filter(
    !is.na(menthlth_days),
    !is.na(physhlth_days),
    !is.na(sleep_hrs),
    !is.na(age),   age >= 18,
    !is.na(income_cat),
    !is.na(sex),
    !is.na(exercise)
  )

# ── Analytic sample (reproducible random sample) ────────────────────────────
set.seed(553)
brfss_mlr <- brfss_mlr %>%
  select(menthlth_days, physhlth_days, sleep_hrs, age,
         income_cat, income_f, sex, exercise, bmi) %>%
  slice_sample(n = 5000)

# Save for lab activity

tibble(Metric = c("Observations", "Variables"),
       Value  = c(nrow(brfss_mlr), ncol(brfss_mlr))) %>%
  kable(caption = "Analytic Dataset Dimensions") %>%
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

