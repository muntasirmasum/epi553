# Confirm that each lecture's brfssdata code reproduces the Spring 2026 sample.
#
# data-raw/reference-2026/ holds the analytic samples the Spring 2026 lectures
# used (built from the raw CDC XPT files). When a lecture is converted to load
# BRFSS with brfssdata, add a builder below that copies the lecture's data code,
# then run from the project root:
#
#   uvr run data-raw/check_reference_samples.R
#
# Every line should print MATCH. Labels that haven attached to the XPT columns
# are ignored; values, types, factor levels, and row order must be identical.

suppressPackageStartupMessages({
  library(tidyverse)
  library(brfssdata)
})

strip_labels <- function(d) {
  d <- as.data.frame(d)
  for (v in names(d)) attr(d[[v]], "label") <- NULL
  d
}

check <- function(name, built) {
  ref <- readRDS(file.path("data-raw", "reference-2026", name))
  same <- identical(strip_labels(built), strip_labels(ref))
  cat(sprintf("%-28s %s\n", name, if (same) "MATCH" else "DIFFERENT"))
  invisible(same)
}

# Simple Linear Regression (lectures/simple-linear-regression.qmd, load-data)
build_slr <- function() {
  d <- read_brfss(
    2020,
    vars = c("_BMI5", "_AGE80", "_SEX", "_EDUCAG", "GENHLTH", "PHYSHLTH", "SLEPTIM1"),
    quiet = TRUE
  ) |>
    janitor::clean_names() |>
    select(bmi5, age80, sex, educag, genhlth, physhlth, sleptim1) |>
    mutate(
      bmi       = bmi5 / 100,
      age       = age80,
      sex       = factor(ifelse(sex == 1, "Male", "Female")),
      education = factor(case_when(
        educag == 1 ~ "< High school",
        educag == 2 ~ "High school graduate",
        educag == 3 ~ "Some college",
        educag == 4 ~ "College graduate"
      ), levels = c("< High school", "High school graduate",
                    "Some college", "College graduate")),
      gen_health_num = ifelse(genhlth  %in% 1:5,  genhlth,  NA_real_),
      sleep_hrs      = ifelse(sleptim1 %in% 1:24, sleptim1, NA_real_),
      phys_days      = ifelse(physhlth %in% 0:30, physhlth, NA_real_)
    )
  set.seed(553)
  d |>
    select(bmi, age, sex, education, gen_health_num, sleep_hrs, phys_days) |>
    filter(bmi > 14.5, bmi < 60, age >= 18, age <= 80) |>
    drop_na() |>
    slice_sample(n = 3000)
}

results <- c(
  check("brfss_slr_2020.rds", build_slr())
)

if (!all(results)) quit(status = 1)
