# EPI 553 notes: moving off RPubs

How the EPI 553 lecture notes moved from RPubs to <https://epi553.muntasirmasum.com>, how to keep working on the site, and what is left to do.

## Status (November 2, 2026)

- **Live:** <https://epi553.muntasirmasum.com>, served by GitHub Pages from the `gh-pages` branch of [muntasirmasum/epi553](https://github.com/muntasirmasum/epi553). HTTPS is enforced.
- **DNS:** CNAME record `epi553 → muntasirmasum.github.io` in Vercel DNS for muntasirmasum.com. The main site and its other records are unchanged.
- **Converted:** Simple Linear Regression (Lecture 05).
- **Remaining:** 17 lectures, 3 labs, and the resource pages (listed below).
- **Local copy:** `~/epi553`, also reachable as `epi553-site` inside the Spring 2027 `epi553` folder. The Spring 2026 sources are reachable as `Epi 553` in the same folder.

## Why this setup

RPubs stops accepting new documents and edits on June 30, 2027. Existing pages stay readable until December 31, 2031, but cannot be corrected after June 2027.

Posit Connect Cloud was the suggested replacement. Its free plan cannot use your own domain (that needs the $59/month plan), and Posit has retired RPubs, Quarto Pub, and bookdown.org hosting within about two years. Owning the address solves the underlying problem: the notes live at `epi553.muntasirmasum.com`, and the host behind it can change by editing one DNS record.

The site is one evolving Quarto website, not a new site each semester. Each lecture keeps one address across years; semester logistics stay in Brightspace. At the end of each semester, a git tag and a GitHub release preserve exactly what students saw.

## Day-to-day workflow

1. Open `~/epi553` in Positron.
2. Edit a `.qmd` file and preview with `quarto preview` in the terminal (it reloads as you save).
3. When it looks right, commit and push `main`, then publish:

   ```bash
   git add -A && git commit -m "Describe the change" && git push
   quarto publish gh-pages --no-prompt
   ```

Things to know:

- **Use uvr's R.** This project runs on `~/.uvr/r-versions/4.6.1`, not `/usr/local/bin/R`. uvr relinks some compiled packages to its own R, and `openssl` crashes under the system R. uvr already set Positron to use its R in this folder, and Quarto reads `QUARTO_R` from `_environment.local` (gitignored). On a new machine, see `README.md`.
- **Add packages with uvr**, never `install.packages()`: `uvr add <package>`. Restore everything with `uvr sync`.
- **Frozen results.** `execute: freeze: auto` stores computed output in `_freeze/`. A lecture reruns only when its `.qmd` changes. Commit `_freeze/` with the source.
- **First run needs internet.** BRFSS lectures load data with brfssdata, which downloads each survey year once and caches it.

## Converting a lecture

Repeat this for each remaining lecture. Simple Linear Regression (`lectures/simple-linear-regression.qmd`) is the worked example to copy from.

1. **Find the published source.** Each lecture folder in `Epi 553/Lectures Notes/` has an `rsconnect/documents/<file>/rpubs.com/rpubs/Publish Document.dcf`. The `.Rmd` named there is the version that went to RPubs. Keep its rendered HTML open for comparison.
2. **Copy it** to `lectures/<slug>.qmd`, using a short lowercase slug (for example `multiple-linear-regression`).
3. **Convert chunk options** to `#|` lines: in R, run `knitr::convert_chunk_header("lectures/<slug>.qmd", type = "yaml")`. Delete the `output:` block.
4. **Set the front matter** like the pilot: `title`, a one-sentence `subtitle`, a `description` for the lecture card, `lecture` (course order number), `unit`, `categories`, `author`, `date-modified: last-modified`, `execute: warning/message: false`, `fig-width: 8`, `fig-height: 5`.
5. **Restructure for the site:**
   - Shift headings down one level (`#` becomes `##`); the title is the only top-level heading.
   - Remove `---` horizontal rules.
   - Add a "Learning objectives" note callout at the top, written from the lecture's own sections.
   - Turn quoted tips into callouts: interpretation tips become `callout-tip`, key distinctions `callout-important`, caveats and cautions `callout-warning`, side notes `callout-note`.
   - Replace em dashes in headings, captions, and plot titles with colons or commas.
6. **Load the data the new way.**
   - BRFSS: read only the needed variables with `read_brfss(year, vars = c(...))` followed by `janitor::clean_names()`, then the lecture's original recoding and `set.seed()` sample. Add the same code as a builder in `data-raw/check_reference_samples.R` and run `uvr run data-raw/check_reference_samples.R`. Every line must print `MATCH` against the Spring 2026 sample in `data-raw/reference-2026/` before you go on.
   - Lectures that read another lecture's `.rds` (Tests of Hypotheses, Logistic Part 2, Logistic Applications, Poisson) rebuild that sample with the same brfssdata code instead.
   - Delete `saveRDS()` side effects, absolute paths, and `cache=TRUE`.
7. **Modernize the code:** change `%>%` to `|>`. Check for `.` used as a pipe placeholder (for example `data = .`); `.` inside `~ round(., 2)` is fine.
8. **Lab and submission text:**
   - Lab setup chunks repeat the full data code so a student's lab file runs on its own.
   - Submission goes to Brightspace: the `.qmd` plus the rendered HTML, with the `embed-resources: true` YAML block shown in the pilot.
   - Print session info with the home folder shortened to `~` (copy the pilot's last chunk).
9. **Accessibility:**
   - Render once, open each PNG in `_site/lectures/<slug>_files/figure-html/`, and write a `fig-alt` for every figure that states the chart type, axes, and the pattern a student should see.
   - Interactive plotly figures cannot take `fig-alt`. Add a `[Figure description: ...]{.visually-hidden}` line after the chunk.
   - Run the checker (below) and fix every violation.
10. **Add it to the sidebar** in `_quarto.yml` under `Lectures`, in course order.
11. **Check against the published version.** Compare key numbers (coefficients, odds ratios, p-values, test statistics) with the RPubs HTML. Read every sentence that states a conclusion: hard-coded words like "reject" or "significant" must agree with the numbers. Make them follow the result with inline R, as in the pilot's hypothesis test.
12. **Publish** (workflow above).

### Accessibility checker

`tools/a11y/check.js` runs axe-core (WCAG 2.0 and 2.1, levels A and AA) on rendered pages in light and dark mode, at desktop width and at 320 px, and reports horizontal overflow.

```bash
cd tools/a11y && npm install && cd ../..        # once
quarto render
(cd _site && python3 -m http.server 4321 &)     # serve the site locally
NODE_PATH=$(npm root -g) node tools/a11y/check.js http://localhost:4321/ \
  index.html lectures/index.html lectures/<slug>.html
```

It needs Node, Google Chrome, and Playwright installed globally (`npm install -g playwright`). Aim for `TOTAL violation groups: 0`. Automated checks catch only part of WCAG, so also read the alt text against the figures and tab through the page with the keyboard.

## Remaining lectures

Paths are relative to `Spring 2026/Epi 553/Lectures Notes/`. Lecture numbers follow the Spring 2026 order.

| # | Lecture | Published source | Data | Notes |
|---|---------|------------------|------|-------|
| 01 | Review of EPI 552 | `epi553_review552.Rmd` | Simulated | Uses `theme: cosmo`; date uses `Sys.Date()` |
| 02 | Analysis of Variance (ANOVA) | `ANOVA/files2/anova_lecture_Feb3.Rmd` | NHANES package | A newer copy in `ANOVA/files_Feb1/` differs by one comment |
| 03 | Matrix Algebra for Regression | `Matrix Algebra/Matrix_Algebra_Lecture.Rmd` | NHANES package | Ignore the older duplicate at the folder root |
| 04 | Statistical Modeling in Epidemiology | `Modeling/Modeling_Lecture.Rmd` | BRFSS 2023 | Reference sample `brfss_subset_2023.rds` |
| 06 | Multiple Linear Regression | `Multiple Linear Regression/MLR_Lecture.Rmd` | BRFSS 2020 | Source was edited after its last publish; compare carefully |
| 07 | Tests of Hypotheses in MLR | `Tests of Hypotheses/Tests_of_Hypotheses_Lecture.Rmd` | BRFSS 2020 | Read the MLR sample in Spring 2026 |
| 08 | Dummy Variables | `Dummy Variables/Dummy_Variables_Lecture.Rmd` | BRFSS 2020 | |
| 09 | Confounding and Interactions | `Confounding Interaction/Confounding_Interaction_Lecture.Rmd` | BRFSS 2020 | |
| 10 | Model Selection | `Model Selection/Model_Selection_Lecture.Rmd` | BRFSS 2020 | |
| 11 | Regression Diagnostics | `Diagnostics/Diagnostics_Lecture.Rmd` | BRFSS 2020 | |
| 12 | Logistic Regression Part 1 | `Logistic Regression/Logistic_Regression_Part1_Lecture.Rmd` | BRFSS 2020 | Builds the logistic sample later lectures reuse |
| 13 | Logistic Regression Part 2 | `Logistic Regression/Logistic_Regression_Part2_Lecture.Rmd` | BRFSS 2020 | Read Part 1's sample |
| 14 | Polytomous and Ordinal Logistic | `Polytomous Regression/Polytomous_Regression_Lecture.Rmd` | BRFSS 2020 | |
| 15 | Logistic Regression Applications | `Logistic Regression Applications/Logistic_Regression_Applications_Lecture.Rmd` | BRFSS 2020 | Read Part 1's sample |
| 16 | Poisson Regression | `Poisson and Survival/Poisson_Regression_Lecture.Rmd` | BRFSS 2020 | Read Part 1's sample; no local HTML, compare with RPubs |
| 17 | Survival Analysis | `Poisson and Survival/Survival_Analysis_Lecture.Rmd` | `survival::lung` | No local HTML, compare with RPubs |
| 18 | Data Visualization in R | `Data Visualization/Data_Visualization_Lecture.Rmd` | Several packages | `tigris` needs internet; add `waffle` with `uvr add cran/waffle@master`; link the existing slide deck at muntasirmasum.github.io/epi553-data-viz |

Labs and resources:

| Page | Source (relative to `Spring 2026/Epi 553/`) | Goes in |
|------|---------------------------------------------|---------|
| Lab 1: Exploring NHANES | `In-Class R Lab Activities/EPI553_Lab01_NHANES_DataExploration.Rmd` | `labs/` |
| Lab 2: ANOVA | `Lectures Notes/ANOVA/files_Feb1/anova_lab_activity_student.Rmd` | `labs/` |
| Lab 3: Correlation | `Lectures Notes/Correlation/Correlation_Lab_Spring2026.Rmd` | `labs/` |
| Intro to R | `Lectures Notes/EPI553_Intro_to_R_Jan22.qmd` (drop its missing `style.css`) | `resources/` |
| R setup check | `Week 1 R Setup Chunk/Week1_Setup_Check.Rmd` (remove RPubs steps) | `resources/` |
| Setup and workflow checklist | `Assignments/Ungraded Assignment/Setup_Workflow_Checklist.Rmd` (remove RPubs steps) | `resources/` |
| Submitting your work | New page replacing the RPubs quick guide: render with embedded resources, upload `.qmd` and HTML to Brightspace | `resources/` |

Each lab page should offer a downloadable project `.zip` (the lab `.qmd`, with the brfssdata code at the top).

## Never publish

TA lab solutions (`*_Lab_Solution_TA.*`), anything in `Final Paper/` (student work), quizzes, exams, raw XPT files, `rsconnect/` folders, and `*_cache/` folders.

## Other to-dos

- **Your website.** Change the RPubs card on muntasirmasum.com's teaching page to a "Course sites" list linking <https://epi553.muntasirmasum.com>. Work in `Summer 2026/academic-website/design-port` (current); `~/academic-website` is behind and needs `git pull` first. The card is at `teaching.html` lines 80 to 83; `DEPLOY.md` line 15 mentions RPubs. Pushing to `main` redeploys on Vercel.
- **Brightspace.** Point the Spring 2027 course shell to the new lecture addresses.
- **TA lab solution.** Regenerate the Simple Linear Regression solution from the lecture's sample. The lab now uses the lecture's 3,000 adults, and the published version's conclusion was wrong (see below).
- **Content to review in the pilot.**
  - The learning objectives are new text.
  - Section 8.2 calls the residual curve "very slight", but it bends from about -5 to +1.5.
- **Corrections carried over from Spring 2026.**
  - The published page said "we reject H0" at p = 0.396; the new page states the conclusion from the p-value.
  - The diagnostic plot drew Cook's distance where the text described Residuals vs. Leverage; the new page uses R's default panels.
  - Check the other lectures for the same two kinds of mismatch.
- **RPubs, before June 30, 2027.** Update each of the 25 EPI 553 documents on RPubs with a short "This lecture has moved to <new address>" note at the top. From Positron's R console, use `rsconnect::rpubsUpload(title, contentFile, originalDoc, id = <id from the lecture's .dcf>)`; test on one document first. Leave the 25 older UTSA documents alone.

## Each semester

- **At the end:** `git tag spring-2027 && git push --tags`, then create a GitHub release with the rendered `_site` folder zipped.
- **At the start:** update `_variables.yml` (semester, instructor details) and the schedule page, then publish.

## Adding another course

Copy `_extensions/muntasirmasum/course/` (theme, brand, accessibility fixes) into a new repository, add the same `include-after-body` and `theme` lines to its `_quarto.yml`, and give it its own subdomain (for example `epi501.muntasirmasum.com`) with one more CNAME record. Later, the extension can move to its own repository so one fix updates every course.

## Known small issues

- The sidebar section labels are not uppercase; the CSS selector for them does not match Quarto's markup.
- The lecture-card template prints "undefined" if a lecture lacks `lecture` or `unit` in its front matter.
- Lecture order is set in three places (the `lecture` field, the sidebar list, and previous/next links).
- The footer year (© 2026) is hard-coded in `_quarto.yml`.
- Collapsible callout headers use the browser's default focus outline instead of the theme's.
