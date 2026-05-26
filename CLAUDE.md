# CLAUDE.md

## Project Overview

PhD dissertation (Aim 1) analyzing whether the US can halve premature mortality (probability of dying before age 70, 70q0) by 2050. State-level analysis of 51 jurisdictions (50 states + DC), 1990-2023, with cause-specific decomposition using Karlsson (2025) priority conditions.

## Tech Stack

- **Language:** R (RStudio project: `uw-phd-dissertation1.Rproj`)
- **Core packages:** `data.table` (primary data manipulation), `ggplot2`, `readxl`, `parallel`/`doParallel`/`foreach`
- **Additional packages:** `dplyr`, `tidyr`, `countrycode`, `stringr`, `RColorBrewer`, `gmodels`
- **Style:** Pure `data.table` syntax in pipeline scripts 02-04 (no dplyr/pipes). `dplyr`/`tidyr` loaded by `00_main.R` but reserved for ad hoc exploratory work only.
- **Encoding:** UTF-8, 2-space indentation

## Running Code

No build system. Scripts run sequentially via the orchestrator:

```r
Rscript code/00_main.R
```

Or source individual scripts in RStudio (they depend on `00_main.R`'s environment).

`00_main.R` hardcodes `wd` to a local path (`C:/Users/wrgar/OneDrive - UW/04Dissertation/uw-phd-aim1/`). Update this if running elsewhere. It also creates a temp directory at `../temp/` for intermediate processing.

## Pipeline Structure

| Script | Purpose | Key Outputs |
|--------|---------|-------------|
| `00_main.R` | Orchestrator: sets paths, loads libraries, sources scripts 01-04 | -- |
| `01_utils.R` | Helper functions (`create_age_groups()`) | -- |
| `02_load_inputs.R` | Reads GBD 2023 CSVs + Karlsson cause mapping, builds cause-grouped mortality tables | `data/processed/*.rds` |
| `03_ppd_estimation_trends_state.R` | Computes PPD (70q0) per state/year/sex, AARI, 50-by-50 progress tracking | `output/model/ppd_*.csv` |
| `04_ppd_decomposition_state_cause.R` | Stepwise + Horiuchi decomposition of PPD gap vs. reference populations | `output/model/decomp_*.csv`, `output/model/priority_conditions_by_state.csv` |
| `05_ppd_estimation_subgroups_state.R` | Stub -- planned Norheim et al. replication for subgroup analysis | -- |

## Repository Layout

```
code/                 R analysis scripts (numbered pipeline)
data/
  raw/gbd/mortality/  GBD 2023 CSVs organized by cause group (git-ignored)
  processed/          .rds files produced by 02_load_inputs.R (tracked)
  interim/            Reserved for intermediate outputs
output/
  model/              Final CSVs: PPD estimates, AARI, decomposition results
  paper/              Reserved for paper-ready tables/figures
  report/             Reserved for report outputs
  slides/             Reserved for presentation outputs
docs/                 references.bib, prompts
paper/                Dissertation writing (placeholder)
tests/                Placeholder
library/              Reference PDFs (git-ignored except .md)
```

## Key Data Files

**Processed (tracked in git):**
- `data/processed/state_age_sex_mortality_gbd.rds` -- all-cause state mortality (input to script 03)
- `data/processed/mx_state_cause.rds` -- state x age x sex x cause_group rates
- `data/processed/mx_ref_western_europe.rds` -- Western Europe reference rates
- `data/processed/mx_ref_local_best3.rds` -- 3 lowest-PPD US states reference
- `data/processed/cause_mapping_clean.rds` -- cause-to-cause_group crosswalk
- `data/processed/Karlsson2025_GBD_US_mapping_final.xlsx` -- source cause mapping Excel

**Raw inputs (git-ignored):**
- `data/raw/gbd/mortality/allcause-state/` -- all-cause state mortality CSV
- `data/raw/gbd/mortality/{infectious_childhood,ncd7_cvd-dm,injuries_disorders,ncd_infectious,ncd_tobacco}/` -- cause-specific folders with multi-part CSVs

## Methodological Notes

- **PPD formula:** Abridged life table with unequal age intervals. `qx = n * mx / (1 + (n - ax) * mx)` where n = interval width. ax = 0.1 for infants, n/2 otherwise. PPD = 1 - prod(1 - qx) over ages 0-69.
- **AARI:** Average annual rate of improvement = `(q_start / q_end)^(1/n) - 1`
- **Decomposition:** Stepwise replacement (Andreev/Shkolnikov/Begun 2002) and Horiuchi continuous-change (Horiuchi/Wilmoth/Pletcher 2008). Compares each state to Western Europe and best-3 US states.
- **Cause mapping:** Karlsson (2025) priority conditions; unmapped causes go to "Other" residual.
- **Rate vector layout:** Cause-within-age ordering: `[age0_c1, age0_c2, ..., age1_c1, ...]`
- **Age structure:** 16 age groups below 70: widths 1, 1, 3, then 5-year groups from 5-9 to 65-69.

## Conventions

- All scripts assume `00_main.R` has been sourced first (sets `wd`, `wd_data`, `wd_outp`, `wd_raw`, loads libraries)
- Scripts use `stopifnot()` assertions for data integrity checks
- Sex is always stratified (never "Both")
- Age cutoff for PPD is 70 (ages 0-69 inclusive)
- Stroke subtypes (Ischemic stroke, Intracerebral hemorrhage) used instead of aggregate when available
- Horiuchi integration uses N=20 steps

## Git Notes

- Raw data git-ignored (`data/raw/**/*.*` except `.md`); processed `.rds` files are tracked
- Library PDFs git-ignored except `.md` files
- HTML/PDF outputs git-ignored
- `.claude/` directory git-ignored
