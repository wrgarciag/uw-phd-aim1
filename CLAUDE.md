# CLAUDE.md

## Project Overview

PhD dissertation (Aim 1) analyzing whether the US can halve premature mortality (probability of dying before age 70, _{70}q_0) by 2050. State-level analysis of 51 jurisdictions (50 states + DC), 1990–2023, with cause-specific decomposition using Karlsson (2025) priority conditions.

## Tech Stack

- **Language:** R (RStudio project: `uw-phd-dissertation1.Rproj`)
- **Core packages:** `data.table` (primary data manipulation), `ggplot2`, `readxl`, `parallel`/`doParallel`/`foreach`
- **Style:** Pure `data.table` syntax in pipeline scripts (no dplyr/pipes in `02_load_inputs.R` onward)
- **IDE:** UTF-8 encoding, 2-space indentation

## Running Code

No build system. Scripts run sequentially via the orchestrator:

```r
# Run the full pipeline
Rscript code/00_main.R

# Or source individual scripts in RStudio (they depend on 00_main.R's environment)
```

`00_main.R` sets working directories and sources scripts in order. It hardcodes `wd` to a local path — update this if running on a different machine.

## Pipeline Structure

| Script | Purpose | Outputs |
|--------|---------|---------|
| `00_main.R` | Orchestrator: sets paths, loads libraries, sources all scripts | — |
| `01_utils.R` | Helper functions (e.g., `create_age_groups()`) | — |
| `02_load_inputs.R` | Reads GBD 2023 CSVs + Karlsson cause mapping, builds cause-grouped mortality tables | `data/processed/*.rds` |
| `03_ppd_estimation_trends_state.R` | Computes PPD (70q0) per state/year/sex, AARI, 50-by-50 progress tracking | `output/ppd_*.csv` |
| `04_ppd_decomposition_state_cause.R` | Stepwise + Horiuchi decomposition of PPD gap vs. reference populations | `output/decomp_*.csv`, `output/priority_conditions_by_state.csv` |
| `05_ppd_estimation_subgroups_state.R` | Placeholder for subgroup analysis (not yet implemented) |

## Repository Layout

```
code/              R analysis scripts (numbered pipeline)
data/
  raw/gbd/         GBD 2023 CSVs organized by cause group (git-ignored)
  processed/       .rds files produced by 02_load_inputs.R
  interim/         (reserved for intermediate outputs)
output/            Final CSVs: PPD estimates, AARI, decomposition results
docs/              References (references.bib), prompts
paper/             Dissertation writing (placeholder)
tests/             (placeholder)
library/           Reference PDFs (git-ignored except .md)
```

## Key Data Files

**Inputs (git-ignored raw):**
- `data/raw/gbd/mortality/allcause-state/` — all-cause state mortality
- `data/raw/gbd/mortality/{infectious_childhood,ncd7_cvd-dm,injuries_disorders,ncd_infectious,ncd_tobacco}/` — cause-specific folders

**Processed (tracked):**
- `data/processed/Karlsson2025_GBD_US_mapping_final.xlsx` — cause-to-priority-condition crosswalk
- `data/processed/mx_state_cause.rds` — state × age × sex × cause_group rates
- `data/processed/mx_ref_western_europe.rds` — Western Europe reference rates
- `data/processed/mx_ref_local_best3.rds` — 3 lowest-PPD US states reference

## Methodological Notes

- **PPD formula:** Abridged life table with unequal age intervals. `qx = n * mx / (1 + (n - ax) * mx)` where n = interval width, ax = 0.1 for infants, n/2 otherwise. PPD = 1 − ∏(1 − qx) over ages 0–69.
- **AARI:** Average annual rate of improvement = `(q_start / q_end)^(1/n) - 1`
- **Decomposition:** Two methods (stepwise replacement, Horiuchi continuous-change) comparing each state to Western Europe and best-3 US states
- **Cause mapping:** Karlsson (2025) priority conditions framework; unmapped causes → "Other" residual category
- **Rate vector layout:** Cause-within-age ordering: `[age0_c1, age0_c2, ..., age1_c1, ...]`

## Conventions

- All scripts assume `00_main.R` has been sourced first (sets `wd`, `wd_data`, `wd_outp`, `wd_raw`, loads libraries)
- Scripts use `stopifnot()` assertions for data integrity checks
- Sex is always stratified (never "Both")
- Age cutoff for PPD is 70 (ages 0–69 inclusive)
- Stroke subtypes (Ischemic stroke, Intracerebral hemorrhage) used instead of aggregate when available

## Git Notes

- Raw data git-ignored (`data/raw/**/*.*` except `.md`); `.rds` processed files are tracked
- Library PDFs git-ignored except `.md` files
- HTML/PDF outputs git-ignored
- No Git LFS currently configured
