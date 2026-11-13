# Spring 2026 data code, copied verbatim from Diagnostics_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

brfss_dx <- brfss_full |>
  mutate(
    # Outcome
    menthlth_days = case_when(
      menthlth == 88                  ~ 0,
      menthlth >= 1 & menthlth <= 30 ~ as.numeric(menthlth),
      TRUE                           ~ NA_real_
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
    )
  ) |>
  filter(
    !is.na(menthlth_days), !is.na(physhlth_days), !is.na(sleep_hrs),
    !is.na(age), age >= 18, !is.na(sex), !is.na(bmi),
    !is.na(exercise), !is.na(income_cat)
  )

set.seed(1220)
brfss_dx <- brfss_dx |>
  dplyr::select(menthlth_days, physhlth_days, sleep_hrs, age, sex,
                bmi, exercise, income_cat) |>
  slice_sample(n = 5000)

# Save for lab

tibble(Metric = c("Observations", "Variables"),
       Value  = c(nrow(brfss_dx), ncol(brfss_dx))) |>
  kable(caption = "Analytic Dataset Dimensions") |>
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

