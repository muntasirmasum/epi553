# Spring 2026 data code, copied verbatim from Modeling_Lecture.Rmd
# (chunks: create-subset, recode-data), minus the saveRDS()/write_rds() call.
# Expects `brfss_full` with janitor-cleaned names. Used only by check_reference_samples.R.

# Select variables of interest and create analytic dataset
set.seed(553)  # For reproducibility

brfss_subset <- brfss_full %>%
  select(
    # Outcome: Diabetes status
    diabete4,
    # Demographics
    age_g,      # Age category
    sex,         # Sex
    race,       # Race/ethnicity
    educag,     # Education level
    incomg1,    # Income category
    # Health behaviors
    bmi5cat,    # BMI category
    exerany2,     # Physical activity
    smokday2,     # Smoking frequency
    # Health status
    genhlth,      # General health
    rfhype6,    # High blood pressure
    rfchol3     # High cholesterol
  ) %>%
  # Filter to complete cases only
  drop_na() %>%
  # Sample 2000 observations for manageable analysis
  slice_sample(n = 2000)

# Display subset dimensions
cat("Working subset dimensions:",
    nrow(brfss_subset), "observations,",
    ncol(brfss_subset), "variables\n")

# Create clean dataset with recoded variables
brfss_clean <- brfss_subset %>%
  mutate(
    # Outcome: Diabetes (binary)
    diabetes = case_when(
      diabete4 == 1 ~ 1,  # Yes
      diabete4 %in% c(2, 3, 4) ~ 0,  # No, pre-diabetes, or gestational only
      TRUE ~ NA_real_
    ),

    # Age groups
    age_group = factor(case_when(
      age_g == 1 ~ "18-24",
      age_g == 2 ~ "25-34",
      age_g == 3 ~ "35-44",
      age_g == 4 ~ "45-54",
      age_g == 5 ~ "55-64",
      age_g == 6 ~ "65+"
    ), levels = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+")),

    # Age continuous (midpoint of category)
    age_cont = case_when(
      age_g == 1 ~ 21,
      age_g == 2 ~ 29.5,
      age_g == 3 ~ 39.5,
      age_g == 4 ~ 49.5,
      age_g == 5 ~ 59.5,
      age_g == 6 ~ 70
    ),

    # Sex
    sex = factor(ifelse(sex == 1, "Male", "Female")),

    # Race/ethnicity
    race = factor(case_when(
      race == 1 ~ "White",
      race == 2 ~ "Black",
      race == 3 ~ "Native American",
      race == 4 ~ "Asian",
      race == 5 ~ "Native Hawaiian/PI",
      race == 6 ~ "Other",
      race == 7 ~ "Multiracial",
      race == 8 ~ "Hispanic"
    )),

    # Education (simplified)
    education = factor(case_when(
      educag == 1 ~ "< High school",
      educag == 2 ~ "High school graduate",
      educag == 3 ~ "Some college",
      educag == 4 ~ "College graduate"
    ), levels = c("< High school", "High school graduate", "Some college", "College graduate")),

    # Income (simplified)
    income = factor(case_when(
      incomg1 == 1 ~ "< $25,000",
      incomg1 == 2 ~ "$25,000-$49,999",
      incomg1 == 3 ~ "$50,000-$74,999",
      incomg1 == 4 ~ "$75,000+",
      incomg1 == 5 ~ "Unknown"
    ), levels = c("< $25,000", "$25,000-$49,999", "$50,000-$74,999", "$75,000+", "Unknown")),

    # BMI category
    bmi_cat = factor(case_when(
      bmi5cat == 1 ~ "Underweight",
      bmi5cat == 2 ~ "Normal",
      bmi5cat == 3 ~ "Overweight",
      bmi5cat == 4 ~ "Obese"
    ), levels = c("Underweight", "Normal", "Overweight", "Obese")),

    # Physical activity (binary)
    phys_active = ifelse(exerany2 == 1, 1, 0),

    # Current smoking
    current_smoker = case_when(
      smokday2 == 1 ~ 1,  # Every day
      smokday2 == 2 ~ 1,  # Some days
      smokday2 == 3 ~ 0,  # Not at all
      TRUE ~ 0
    ),

    # General health (simplified)
    gen_health = factor(case_when(
      genhlth %in% c(1, 2) ~ "Excellent/Very good",
      genhlth == 3 ~ "Good",
      genhlth %in% c(4, 5) ~ "Fair/Poor"
    ), levels = c("Excellent/Very good", "Good", "Fair/Poor")),

    # Hypertension
    hypertension = ifelse(rfhype6 == 2, 1, 0),

    # High cholesterol
    high_chol = ifelse(rfchol3 == 2, 1, 0)
  ) %>%
  # Select only the clean variables
  select(diabetes, age_group, age_cont, sex, race, education, income,
         bmi_cat, phys_active, current_smoker, gen_health,
         hypertension, high_chol) %>%
  # Remove any remaining missing values
  drop_na()

# Save the cleaned subset for future use

cat("Clean dataset saved with", nrow(brfss_clean), "complete observations\n")

