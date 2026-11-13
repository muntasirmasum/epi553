# Prove that brfssdata reproduces every Spring 2026 BRFSS sample.
#
# data-raw/reference-2026/ holds the analytic samples the Spring 2026 lectures
# used (built from the raw CDC XPT files). data-raw/builders-2026/ holds each
# lecture's data code, copied verbatim. This script feeds that code the same
# variables read with brfssdata::read_brfss() and compares the result with the
# saved sample. Run from the project root:
#
#   uvr run data-raw/check_reference_samples.R
#
# Every line should print MATCH. Labels that haven attached to the XPT columns
# are ignored; values, types, factor levels, and row order must be identical.
#
# Lectures whose samples were redefined for Spring 2027 (smoking status with
# never-smokers, the 2023 Modeling recode) still check their 2026 code here:
# a MATCH shows the data source is right before the definition changes.

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(knitr)
  library(kableExtra)
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
  cat(sprintf("%-28s %s (n = %s)\n", name, if (same) "MATCH" else "DIFFERENT", nrow(built)))
  if (!same) print(all.equal(strip_labels(built), strip_labels(ref)))
  invisible(same)
}

# Run a verbatim 2026 builder on brfssdata input and return the named object.
run_builder <- function(builder, year, vars, object) {
  env <- new.env()
  env$brfss_full <- read_brfss(year, vars = vars, quiet = TRUE) |>
    janitor::clean_names()
  invisible(capture.output(
    sys.source(file.path("data-raw", "builders-2026", builder), envir = env)
  ))
  get(object, envir = env)
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

# CDC variable names each 2026 builder needs (cleaned names in comments)
vars_2020 <- list(
  mlr = c("MENTHLTH", "PHYSHLTH", "SLEPTIM1", "_AGE80", "INCOME2", "SEXVAR",
          "EXERANY2", "_BMI5"),
  dv  = c("MENTHLTH", "PHYSHLTH", "SLEPTIM1", "_AGE80", "SEXVAR", "EDUCA",
          "GENHLTH", "MARITAL"),
  ci  = c("PHYSHLTH", "SLEPTIM1", "MENTHLTH", "_AGE80", "SEXVAR", "EDUCA",
          "EXERANY2", "GENHLTH", "INCOME2"),
  ms  = c("PHYSHLTH", "SLEPTIM1", "MENTHLTH", "_AGE80", "SEXVAR", "EDUCA",
          "EXERANY2", "GENHLTH", "INCOME2", "_BMI5"),
  dx  = c("MENTHLTH", "PHYSHLTH", "SLEPTIM1", "_AGE80", "SEXVAR", "_BMI5",
          "EXERANY2", "INCOME2"),
  logistic = c("MENTHLTH", "PHYSHLTH", "SLEPTIM1", "_AGE80", "SEXVAR", "_BMI5",
               "EXERANY2", "INCOME2", "SMOKDAY2"),
  polytomous = c("GENHLTH", "_AGE80", "SEXVAR", "_BMI5", "EXERANY2", "INCOME2",
                 "SMOKDAY2")
)
vars_2023_modeling <- c("DIABETE4", "_AGE_G", "_SEX", "_RACE", "_EDUCAG",
                        "_INCOMG1", "_BMI5CAT", "EXERANY2", "SMOKDAY2",
                        "GENHLTH", "_RFHYPE6", "_RFCHOL3")

results <- c(
  check("brfss_slr_2020.rds", build_slr()),
  check("brfss_mlr_2020.rds", run_builder("mlr.R", 2020, vars_2020$mlr, "brfss_mlr")),
  check("brfss_dv_2020.rds", run_builder("dv.R", 2020, vars_2020$dv, "brfss_dv")),
  check("brfss_ci_2020.rds", run_builder("ci.R", 2020, vars_2020$ci, "brfss_ci")),
  check("brfss_ms_2020.rds", run_builder("ms.R", 2020, vars_2020$ms, "brfss_ms")),
  check("brfss_dx_2020.rds", run_builder("dx.R", 2020, vars_2020$dx, "brfss_dx")),
  check("brfss_logistic_2020.rds",
        run_builder("logistic.R", 2020, vars_2020$logistic, "brfss_logistic")),
  check("brfss_polytomous_2020.rds",
        run_builder("polytomous.R", 2020, vars_2020$polytomous, "brfss_poly")),
  check("brfss_subset_2023.rds",
        run_builder("modeling_2023.R", 2023, vars_2023_modeling, "brfss_clean"))
)

if (!all(results)) quit(status = 1)
