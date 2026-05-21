
# IHME GBD data

# State level - all causes GBD 2023----

# Permanent link to GBD 2023 data for all causes
#https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/80190239c3cb9d535ef29f269e2f9a05

# This dataset includes all-cause mortality rates and counts by state from 1990-2023
# broken down by age and sex

# ── 1. Load ────────────────────────────────────────────────────────────────────
dt_mort_all <- fread(paste0(wd_raw, "gbd/mortality/allcause-state/",
                            "IHME-GBD_2023_DATA-1203a526-1.csv"))

# File profile (242 352 rows × 18 cols, 34 MB):
#   measure_name     : "Deaths" only
#   cause_name       : "All causes" only
#   metric_name      : "Number" | "Rate"
#   population_group : "All Population" only
#   sex_name         : "Male" | "Female" | "Both"
#   age_name         : "<1 year", "12-23 months", "2-4 years", "5-9 years", …, "95+ years"
#   location_name    : US states + Global + some super-regions
#   year             : 1990–2023
#   val / upper / lower : point estimate + 95 % UI

# ── 2. Keep only what the state_age_sex_mortality file needs ───────────────────
dt_mort <- dt_mort_all[
  metric_name == "Rate" &          # keep death *rate* (per 100 000); drop raw counts
    sex_name   != "Both"           # keep Male / Female only; drop aggregate "Both"
]

# ── 3. Keep US states only (drop Global / super-regions / sub-national non-US) ─
#   GBD embeds US states by location_name — filter to those that appear in a
#   canonical state list, or use location_id range if you know GBD's coding.
us_states <- c(
  "Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut",
  "Delaware","Florida","Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa",
  "Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan",
  "Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada",
  "New Hampshire","New Jersey","New Mexico","New York","North Carolina",
  "North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
  "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont",
  "Virginia","Washington","West Virginia","Wisconsin","Wyoming",
  "District of Columbia"
)

dt_mort <- dt_mort[location_name %in% us_states]

# ── 4. Harmonise age labels → ordered age_group factor ────────────────────────
#   GBD uses mixed formats; recode to a clean consistent label
age_recode <- c(
  "<1 year"     = "Under 1",
  "12-23 months"= "1",          # collapses into early-childhood if needed
  "2-4 years"   = "2-4",
  "5-9 years"   = "5-9",
  "10-14 years" = "10-14",
  "15-19 years" = "15-19",
  "20-24 years" = "20-24",
  "25-29 years" = "25-29",
  "30-34 years" = "30-34",
  "35-39 years" = "35-39",
  "40-44 years" = "40-44",
  "45-49 years" = "45-49",
  "50-54 years" = "50-54",
  "55-59 years" = "55-59",
  "60-64 years" = "60-64",
  "65-69 years" = "65-69",
  "70-74 years" = "70-74",
  "75-79 years" = "75-79",
  "80-84 years" = "80-84",
  "85-89 years" = "85-89",
  "90-94 years" = "90-94",
  "95+ years"   = "95+"
)

dt_mort[, age_group := age_recode[age_name]]

age_to_numeric <- c(
  "Under 1"  =  0L,   # "<1 year"      → infants (ax = 0.1 applied by script)
  "1"        =  1L,   # "12-23 months" → toddlers, if retained
  "2-4"      =  2L,   # GBD 2-4 years  — note: 5-year lifetable collapses 1,2-4→1-4
  "5-9"      =  5L,
  "10-14"    = 10L,
  "15-19"    = 15L,
  "20-24"    = 20L,
  "25-29"    = 25L,
  "30-34"    = 30L,
  "35-39"    = 35L,
  "40-44"    = 40L,
  "45-49"    = 45L,
  "50-54"    = 50L,
  "55-59"    = 55L,
  "60-64"    = 60L,
  "65-69"    = 65L,
  "70-74"    = 70L,   # kept in data but filtered out by age < 70 in script
  "75-79"    = 75L,
  "80-84"    = 80L,
  "85-89"    = 85L,
  "90-94"    = 90L,
  "95+"      = 95L
)

dt_mort[, age := age_to_numeric[as.character(age_group)]]

# Drop the 12-23 months band if your model uses Under-1 only
# dt_mort <- dt_mort[age_name != "12-23 months"]

# ── 5. Rename & select final columns ──────────────────────────────────────────
setnames(dt_mort, old = c("location_name", "sex_name", "year", "val", "upper", "lower"),
         new = c("state",          "sex",       "year", "mort_rate", "mort_rate_upper", "mort_rate_lower"))

dt_mort <- dt_mort[, .(state, year, sex, age_group, age,
                       mort_rate, mort_rate_upper, mort_rate_lower)]

# ── 6. Coerce types & set key for fast joins ───────────────────────────────────
dt_mort[, sex       := factor(sex,       levels = c("Male", "Female"))]
dt_mort[, age_group := factor(age_group, levels = unname(age_recode))]
dt_mort[, year      := as.integer(year)]

# Script expects column named `mx`
dt_mort[, mx := mort_rate / 1e5]   # GBD rate is per 100 000; lifetable needs per-person

setkey(dt_mort, state, year, sex, age_group)

# ── 7. Sanity checks ───────────────────────────────────────────────────────────
stopifnot(dt_mort[, uniqueN(state)] == 51L)          # 50 states + DC
stopifnot(!anyNA(dt_mort$mort_rate))
stopifnot(dt_mort[, .N, .(state, year, sex, age_group)][N > 1, .N] == 0L)  # no dups

# ── 8. Save ────────────────────────────────────────────────────────────────────
saveRDS(dt_mort, paste0(wd_data, "state_age_sex_mortality_gbd.rds"))

# Clean up large raw data object to free memory
rm(dt_mort_all,dt_mort)


# Infectious/Childhood cluster diseases GBD 2023----

# Permanent link to US States level GBD 2023 data for I-8 cluster: 
# Neonatal disorders
# Lower respiratory infections
# Diarrheal diseases
# HIV/AIDS and sexually transmitted infections > HIV/AIDS
# Tuberculosis
# Malaria
# Measles
# Pertussis
# Diphtheria
# Tetanus
# Maternal disorders

#https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/49a156c7364d1b9bec523c4eb45f8e05

# NCD 7 - CVD-DM-EPOC cluster diseases GBD 2023----

# Permanent link to US States level GBD 2023 data for NCD 7:

# Ischemic heart disease
# Stroke
# Diabetes mellitus
# Chronic kidney disease due to diabetes 
# Chronic obstructive pulmonary disease
# Asthma

# https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/8587d602cbf46f6af6b14c0fc2f15d28

# Injuries, violence and substance use cluster diseases GBD 2023----

# Permanent link to US States level GBD 2023 data for Injuries cluster:

# Road injuries
# Self-harm
# Drug use disorders
# Interpersonal violence
# Mental disorders; substance use disorders
# Alzheimer's disease and other dementias; Parkinson disease; epilepsy; other neurological disorders

#https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/3e3a484f8d7e58b2bd81592448d608ef


# NCDs strongly linked to infections GBD 2023----

# Permanent link to US States level GBD 2023 data for NCDs linked to infections cluster:

# Cervical cancer
# Cirrhosis due to hepatitis B
# Cirrhosis due to hepatitis C
# Liver cancer secondary to hepatitis B
# Liver cancer secondary to hepatitis C
# Rheumatic heart disease
# Stomach cancer

#https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/ad6cbe928f98cac4cdcad44a3f01b69a

# NCDs strongly linked to tobacco GBD 2023----

# Permanent link to US States level GBD 2023 data for NCDs linked to tobacco cluster:

# Larynx cancer
# Mouth and oropharynx cancer
# Trachea, bronchus, and lung cancer


# https://collab2023.healthdata.org/gbd-results?params=gbd-api-2023-permalink/4ed7ea6ee1be8e328de1efdcf4d219e1

