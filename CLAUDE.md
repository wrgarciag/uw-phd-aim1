# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhD dissertation research on whether the United States can halve premature mortality (probability of dying before age 70, denoted _{70}q_{0}) by 2050. Analysis is state-level, covering 1990–2050, with county-level work where feasible.

**Three aims:**
- **Aim 1a:** Construct state-level period life tables (1990–2019), estimate _{70}q_{0}, forecast to 2050 (Lee–Carter, APC, Bayesian hierarchical, trend-dampening)
- **Aim 1b:** Decompose mortality trends by 15 major causes (Arriaga, Pollard, cause-deleted life tables)
- **Aim 1c:** Identify empirically attainable improvement envelopes; compare required vs. observed annualized decline rates

## Tech Stack

- **Language:** R (RStudio project: `uw-phd-dissertation1.Rproj`)
- **Key packages:** `data.table`, `ggplot2`, plus demographic modeling packages
- **Version control:** Git with Git LFS (large data files)
- **IDE settings:** UTF-8 encoding, 2-space indentation

## Running Code

No build system. Run R scripts directly:

```bash
# Run a single script
Rscript code/your_script.R

# Or open RStudio and source interactively
```

## Repository Layout

```
code/        # R analysis scripts
data/
  raw/       # Source data (git-ignored except .md); GBD 2023 archives, CDC WONDER
  interim/   # Intermediate outputs from processing steps
  processed/ # Final analysis-ready datasets
docs/        # Documentation
output/      # Figures, tables, results
paper/       # Dissertation writing
tests/       # Test scripts
```

## Data Sources

- **CDC WONDER** — US mortality microdata
- **GBD 2023** — Global Burden of Disease (zip archives in `data/raw/GBD/`)
- **US Census** — Population denominators
- **ICD-coded** cause-of-death files (requires harmonization across ICD-9/ICD-10 transitions)

## Key Methodological Concepts

- Core outcome: _{70}q_{0} = 1 − ∏(1 − _{5}q_{x}), estimated from period life tables
- Annualized rate of reduction: r = (ln(q0_t2) − ln(q0_t1)) / (t2 − t1)
- Age-standardization and sex-stratification throughout
- Reproducible workflow: scripts in `code/` should read from `data/` and write to `data/interim/`, `data/processed/`, or `output/`

## Git Notes

- Raw data files are git-ignored (`data/raw/**/*.*` except `.md`); use Git LFS for any large files that must be tracked
- Generated HTML and PDF outputs are also git-ignored
