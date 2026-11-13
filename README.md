# EPI 553 lecture notes

Source for <https://epi553.muntasirmasum.com>, the lecture notes and R labs for EPI 553 (Principles of Statistical Inference II) at the University at Albany. Built with [Quarto](https://quarto.org/) and published to GitHub Pages.

## Working on the site

1. Restore the R packages with uvr: `uvr sync`.
2. Render with uvr's own R, not the system R. uvr relinks some compiled packages to its R, and `openssl` crashes under the system R. uvr writes Positron settings for this; for Quarto, create `_environment.local` (gitignored) with
   `QUARTO_R=<home>/.uvr/r-versions/4.6.1/bin/R`.
3. Preview with `quarto preview`; publish with `quarto publish gh-pages`.

`execute: freeze: auto` stores computed results in `_freeze/`, so a lecture reruns only when its source changes. Commit `_freeze/`.

## Data

BRFSS lectures load the survey with the [brfssdata](https://muntasirmasum.github.io/brfssdata/) package. The first run downloads each year once and caches it.

`data-raw/reference-2026/` holds the analytic samples used in Spring 2026. When converting a lecture, add its data code to `data-raw/check_reference_samples.R` and run `uvr run data-raw/check_reference_samples.R`; every line should print `MATCH`.

## Package notes

- `mgcv` uses the CRAN binary (1.9-5 and later); an older pin is no longer needed.
- `waffle` was archived from CRAN, so `uvr.toml` installs it from the CRAN mirror on GitHub (`cran/waffle@master`); `uvr sync` handles it.

## Theme

`_extensions/muntasirmasum/course/` holds the shared look (brand colors and fonts from muntasirmasum.com, light and dark modes) and `a11y.html`, which patches Quarto output for keyboard and screen-reader users. Copy this folder to start another course site.

## License

Content is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).
