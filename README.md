
# Project Brief: Halving Premature Mortality in the United States by 2050
**Principal Investigator:** William Garcia  
**Field:** Demography, Epidemiology, Health Economics
**Time Horizon:** 1990–2050  
**Geographic Scope:** United States (State-level; County-level where feasible)

---

## 1. Project Overview

This project aims to conduct a rigorous demographic and epidemiological analysis to determine whether the United States can halve the probability of premature death (before age 70) by 2050.

The core outcome is:

    _{70}q_{0}

the probability of dying before age 70, derived from period life tables.

---

# Aim 1
## Quantify the baseline and trends of premature mortality in the United States, identify leading causes, and estimate the improvement rate required to achieve a 50% reduction by 2050.

---

## Aim 1a
### Estimate the probability of dying before age 70 (1990–2019) and forecast trajectories to 2050

### Tasks
- Construct state-level period life tables (1990–2019)
- Estimate:
      _{70}q_{0} = 1 - ∏(1 - _{5}q_{x})
- Harmonize mortality and population data across ICD revisions
- Adjust for demographic structure (age, sex)
- Forecast mortality trajectories to 2050 using:
  - Lee–Carter models
  - Age–Period–Cohort models
  - Bayesian hierarchical projections
  - Trend-dampening scenarios

### Outputs
- Historical trends of premature mortality (state × sex)
- Forecast trajectories (2020–2050)
- Annualized rate of reduction required to halve premature mortality

---

## Aim 1b
### Decompose premature mortality trends by cause of death

### Tasks
- Select 15 major causes of death
- Apply decomposition methods:
  - Arriaga decomposition
  - Pollard decomposition
  - Cause-deleted life tables
- Quantify:
  - Contribution of each cause to total change in _{70}q_{0}
  - Geographic heterogeneity
  - Sex-specific contributions
  - Temporal shifts in cause structure

### Outputs
- Cause-specific contributions to premature mortality trends
- Identification of dominant drivers by state
- Decomposition tables and visualizations

---

## Aim 1c
### Identify empirically attainable improvement envelopes

### Concept
Estimate realistic improvement frontiers based on:
- Historical best-performing states
- International comparators
- Observed maximum annualized decline rates
- Epidemiologic feasibility constraints
- Health-system capacity

### Tasks
- Estimate annualized rate of mortality decline:
      r = (ln(q0_t2) - ln(q0_t1)) / (t2 - t1)
- Construct best-practice envelopes
- Compare required rate to historical achievable rates

### Outputs
- State-level feasible improvement envelopes
- Required vs observed decline rates
- Policy-relevant feasibility classification

---

# Data Sources
- CDC WONDER mortality data
- Global Burden of Disease (GBD)
- US Census population estimates
- ICD-coded cause-of-death files
- State-level covariates

---

# Required Skills

## Demographic Methods
- Life table construction
- Multiple decrement life tables
- Mortality decomposition
- Age-standardization

## Statistical Modeling
- Lee–Carter models
- Bayesian hierarchical models
- APC modeling
- Forecast validation

## Epidemiology
- Cause-of-death harmonization
- ICD transitions
- Risk attribution logic

## Data Science
- Large mortality datasets
- Reproducible R workflows. data.table
- Visualization (ggplot2)
- Version control (Git)

---

# Long-Term Objective

Determine whether halving premature mortality in the United States by 2050 is mathematically and epidemiologically feasible, and identify the rate of improvement required across states and causes of death.

