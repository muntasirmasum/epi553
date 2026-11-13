# Spring 2026 data code, copied verbatim from Logistic_Regression_Part1_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

brfss_logistic <- brfss_full |>
  mutate(
    # Binary outcome: frequent mental distress (>= 14 days)
    menthlth_days = case_when(
      menthlth == 88                  ~ 0,
      menthlth >= 1 & menthlth <= 30 ~ as.numeric(menthlth),
      TRUE                           ~ NA_real_
    ),
    fmd = factor(
      ifelse(menthlth_days >= 14, 1, 0),
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),
    # Predictors
    physhlth_days = case_when(
      physhlth == 88                  ~ 0,
      physhlth >= 1 & physhlth <= 30 ~ as.numeric(physhlth),
      TRUE                           ~ NA_real_
    ),
    sleep_hrs = case_when(
      sleptim1 >= 1 & sleptim1 <= 14 ~ as.numeric(sleptim1),
      TRUE                           ~ NA_real_
    ),
    age = age80,
    sex = factor(sexvar, levels = c(1, 2), labels = c("Male", "Female")),
    bmi = ifelse(bmi5 > 0, bmi5 / 100, NA_real_),
    exercise = factor(case_when(
      exerany2 == 1 ~ "Yes",
      exerany2 == 2 ~ "No",
      TRUE          ~ NA_character_
    ), levels = c("No", "Yes")),
    income_cat = case_when(
      income2 %in% 1:8 ~ as.numeric(income2),
      TRUE             ~ NA_real_
    ),
    smoker = factor(case_when(
      smokday2 %in% c(1, 2) ~ "Current",
      smokday2 == 3          ~ "Former/Never",
      TRUE                   ~ NA_character_
    ), levels = c("Former/Never", "Current"))
  ) |>
  filter(
    !is.na(fmd), !is.na(physhlth_days), !is.na(sleep_hrs),
    !is.na(age), age >= 18, !is.na(sex), !is.na(bmi),
    !is.na(exercise), !is.na(income_cat), !is.na(smoker)
  )

set.seed(1220)
brfss_logistic <- brfss_logistic |>
  dplyr::select(fmd, menthlth_days, physhlth_days, sleep_hrs, age, sex,
                bmi, exercise, income_cat, smoker) |>
  slice_sample(n = 5000)

# Save for lab use

tibble(Metric = c("Observations", "Variables", "FMD Cases", "FMD Prevalence"),
       Value  = c(nrow(brfss_logistic), ncol(brfss_logistic),
                  sum(brfss_logistic$fmd == "Yes"),
                  paste0(round(100 * mean(brfss_logistic$fmd == "Yes"), 1), "%"))) |>
  kable(caption = "Analytic Dataset Overview") |>
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

