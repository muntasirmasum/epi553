# Spring 2026 data code, copied verbatim from Model_Selection_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

brfss_ms <- brfss_full |>
  mutate(
    # Outcome
    physhlth_days = case_when(
      physhlth == 88                  ~ 0,
      physhlth >= 1 & physhlth <= 30 ~ as.numeric(physhlth),
      TRUE                           ~ NA_real_
    ),
    # Candidate predictors
    menthlth_days = case_when(
      menthlth == 88                  ~ 0,
      menthlth >= 1 & menthlth <= 30 ~ as.numeric(menthlth),
      TRUE                           ~ NA_real_
    ),
    sleep_hrs = case_when(
      sleptim1 >= 1 & sleptim1 <= 14 ~ as.numeric(sleptim1),
      TRUE                           ~ NA_real_
    ),
    age = age80,
    sex = factor(sexvar, levels = c(1, 2), labels = c("Male", "Female")),
    education = factor(case_when(
      educa %in% c(1, 2, 3) ~ "Less than HS",
      educa == 4             ~ "HS graduate",
      educa == 5             ~ "Some college",
      educa == 6             ~ "College graduate",
      TRUE                   ~ NA_character_
    ), levels = c("Less than HS", "HS graduate", "Some college", "College graduate")),
    exercise = factor(case_when(
      exerany2 == 1 ~ "Yes",
      exerany2 == 2 ~ "No",
      TRUE          ~ NA_character_
    ), levels = c("No", "Yes")),
    gen_health = factor(case_when(
      genhlth == 1 ~ "Excellent",
      genhlth == 2 ~ "Very good",
      genhlth == 3 ~ "Good",
      genhlth == 4 ~ "Fair",
      genhlth == 5 ~ "Poor",
      TRUE         ~ NA_character_
    ), levels = c("Excellent", "Very good", "Good", "Fair", "Poor")),
    income_cat = case_when(
      income2 %in% 1:8 ~ as.numeric(income2),
      TRUE             ~ NA_real_
    ),
    bmi = ifelse(bmi5 > 0, bmi5 / 100, NA_real_)
  ) |>
  filter(
    !is.na(physhlth_days), !is.na(menthlth_days), !is.na(sleep_hrs),
    !is.na(age), age >= 18, !is.na(sex), !is.na(education),
    !is.na(exercise), !is.na(gen_health), !is.na(income_cat), !is.na(bmi)
  )

set.seed(1220)
brfss_ms <- brfss_ms |>
  dplyr::select(physhlth_days, menthlth_days, sleep_hrs, age, sex,
                education, exercise, gen_health, income_cat, bmi) |>
  slice_sample(n = 5000)

# Save for lab

tibble(Metric = c("Observations", "Variables"),
       Value  = c(nrow(brfss_ms), ncol(brfss_ms))) |>
  kable(caption = "Analytic Dataset Dimensions") |>
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

