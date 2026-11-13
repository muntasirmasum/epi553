# Spring 2026 data code, copied verbatim from Dummy_Variables_Lecture.Rmd
# (chunk: prepare-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

brfss_dv <- brfss_full |>
  mutate(
    # Outcome: mentally unhealthy days in past 30
    menthlth_days = case_when(
      menthlth == 88                    ~ 0,
      menthlth >= 1 & menthlth <= 30   ~ as.numeric(menthlth),
      TRUE                             ~ NA_real_
    ),
    # Physical health days
    physhlth_days = case_when(
      physhlth == 88                    ~ 0,
      physhlth >= 1 & physhlth <= 30   ~ as.numeric(physhlth),
      TRUE                             ~ NA_real_
    ),
    # Sleep hours
    sleep_hrs = case_when(
      sleptim1 >= 1 & sleptim1 <= 14   ~ as.numeric(sleptim1),
      TRUE                             ~ NA_real_
    ),
    # Age
    age = age80,
    # Sex
    sex = factor(sexvar, levels = c(1, 2), labels = c("Male", "Female")),
    # Education (6-level raw BRFSS variable EDUCA)
    # 1 = Never attended school or only kindergarten
    # 2 = Grades 1 through 8 (Elementary)
    # 3 = Grades 9 through 11 (Some high school)
    # 4 = Grade 12 or GED (High school graduate)
    # 5 = College 1 year to 3 years (Some college or technical school)
    # 6 = College 4 years or more (College graduate)
    # 9 = Refused
    education = factor(case_when(
      educa %in% c(1, 2, 3) ~ "Less than HS",
      educa == 4             ~ "HS graduate",
      educa == 5             ~ "Some college",
      educa == 6             ~ "College graduate",
      TRUE                   ~ NA_character_
    ), levels = c("Less than HS", "HS graduate", "Some college", "College graduate")),
    # General health status (5-level)
    gen_health = factor(case_when(
      genhlth == 1 ~ "Excellent",
      genhlth == 2 ~ "Very good",
      genhlth == 3 ~ "Good",
      genhlth == 4 ~ "Fair",
      genhlth == 5 ~ "Poor",
      TRUE         ~ NA_character_
    ), levels = c("Excellent", "Very good", "Good", "Fair", "Poor")),
    # Marital status
    marital_status = factor(case_when(
      marital == 1 ~ "Married",
      marital == 2 ~ "Divorced",
      marital == 3 ~ "Widowed",
      marital == 4 ~ "Separated",
      marital == 5 ~ "Never married",
      marital == 6 ~ "Unmarried couple",
      TRUE         ~ NA_character_
    ), levels = c("Married", "Divorced", "Widowed", "Separated",
                  "Never married", "Unmarried couple")),
    # Store the raw education numeric code for the "naive approach" demonstration
    educ_numeric = case_when(
      educa %in% c(1, 2, 3) ~ 1,
      educa == 4             ~ 2,
      educa == 5             ~ 3,
      educa == 6             ~ 4,
      TRUE                   ~ NA_real_
    )
  ) |>
  filter(
    !is.na(menthlth_days),
    !is.na(physhlth_days),
    !is.na(sleep_hrs),
    !is.na(age), age >= 18,
    !is.na(sex),
    !is.na(education),
    !is.na(gen_health),
    !is.na(marital_status)
  )

# Reproducible random sample
set.seed(1220)
brfss_dv <- brfss_dv |>
  select(menthlth_days, physhlth_days, sleep_hrs, age, sex,
         education, gen_health, marital_status, educ_numeric) |>
  slice_sample(n = 5000)

# Save for lab activity

tibble(Metric = c("Observations", "Variables"),
       Value  = c(nrow(brfss_dv), ncol(brfss_dv))) |>
  kable(caption = "Analytic Dataset Dimensions") |>
  kable_styling(bootstrap_options = "striped", full_width = FALSE)

