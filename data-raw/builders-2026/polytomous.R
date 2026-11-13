# Spring 2026 data code, copied verbatim from Polytomous_Regression_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

brfss_poly <- brfss_full |>
  mutate(
    # 3-level ordinal outcome
    genhlth_3 = case_when(
      genhlth %in% c(1, 2) ~ "Excellent/VG",
      genhlth == 3         ~ "Good",
      genhlth %in% c(4, 5) ~ "Fair/Poor",
      TRUE                 ~ NA_character_
    ),
    # Ordered factor for ordinal regression
    genhlth_ord = factor(genhlth_3,
      levels = c("Excellent/VG", "Good", "Fair/Poor"),
      ordered = TRUE),
    # Unordered factor for polytomous regression
    genhlth_nom = factor(genhlth_3,
      levels = c("Excellent/VG", "Good", "Fair/Poor")),
    # Predictors
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
    !is.na(genhlth_ord), !is.na(age), age >= 18, !is.na(sex),
    !is.na(bmi), !is.na(exercise), !is.na(income_cat), !is.na(smoker)
  )

set.seed(1220)
brfss_poly <- brfss_poly |>
  dplyr::select(genhlth_ord, genhlth_nom, age, sex, bmi,
                exercise, income_cat, smoker) |>
  slice_sample(n = 5000)


brfss_poly |>
  count(genhlth_ord) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  kable(col.names = c("General Health", "N", "%"),
        caption = "Outcome Distribution") |>
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

