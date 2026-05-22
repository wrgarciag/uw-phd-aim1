# ============================================================
# 02_load_inputs.R
# Build decomposition-ready mortality rate tables from GBD 2023.
# Pure data.table — no dplyr, no pipes.
#
# Reads:
#   GBD 2023 CSVs: all-cause + 5 cause-specific folders
#   Karlsson (2025) cause mapping: Excel crosswalk
#
# Saves to wd_data:
#   state_age_sex_mortality_gbd.rds  — all-cause state mortality
#                                      (backward-compat with script 03)
#   mx_state_cause.rds               — state x age x sex x cause_group
#   mx_ref_western_europe.rds        — Western Europe reference rates
#   mx_ref_local_best3.rds           — 3 lowest-PPD US states reference
#   cause_mapping_clean.rds          — cause-to-cause_group crosswalk
# ============================================================


# ── Helpers ──────────────────────────────────────────────────

read_gbd_folder <- function(path) {
  files <- list.files(path, pattern = "\\.csv$", full.names = TRUE)
  stopifnot("No CSVs found in GBD folder" = length(files) > 0L)
  rbindlist(lapply(files, fread), use.names = TRUE, fill = TRUE)
}

us_states <- c(
  "Alabama", "Alaska", "Arizona", "Arkansas", "California",
  "Colorado", "Connecticut", "Delaware", "District of Columbia",
  "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
  "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
  "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
  "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
  "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
  "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah",
  "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin",
  "Wyoming"
)

keep_locations <- c(us_states, "Western Europe")

# GBD age_name -> clean label -> numeric start-year
age_label_map <- c(
  "<1 year" = "Under 1", "12-23 months" = "1", "2-4 years" = "2-4",
  "5-9 years" = "5-9", "10-14 years" = "10-14", "15-19 years" = "15-19",
  "20-24 years" = "20-24", "25-29 years" = "25-29", "30-34 years" = "30-34",
  "35-39 years" = "35-39", "40-44 years" = "40-44", "45-49 years" = "45-49",
  "50-54 years" = "50-54", "55-59 years" = "55-59", "60-64 years" = "60-64",
  "65-69 years" = "65-69", "70-74 years" = "70-74", "75-79 years" = "75-79",
  "80-84 years" = "80-84", "85-89 years" = "85-89", "90-94 years" = "90-94",
  "95+ years" = "95+"
)

age_numeric_map <- c(
  "Under 1" = 0L, "1" = 1L, "2-4" = 2L, "5-9" = 5L,
  "10-14" = 10L, "15-19" = 15L, "20-24" = 20L, "25-29" = 25L,
  "30-34" = 30L, "35-39" = 35L, "40-44" = 40L, "45-49" = 45L,
  "50-54" = 50L, "55-59" = 55L, "60-64" = 60L, "65-69" = 65L,
  "70-74" = 70L, "75-79" = 75L, "80-84" = 80L, "85-89" = 85L,
  "90-94" = 90L, "95+" = 95L
)

add_age_cols <- function(dt) {
  dt[, age_group := age_label_map[age_name]]
  dt[, age := age_numeric_map[age_group]]
  invisible(dt)
}


# ==============================================================
# SECTION A: All-cause state mortality
# Backward-compatible save for 03_ppd_estimation_trends_state.R
# ==============================================================

dt_allcause_raw <- fread(paste0(
  wd_raw, "gbd/mortality/allcause-state/IHME-GBD_2023_DATA-1203a526-1.csv"
))

dt_mort <- dt_allcause_raw[
  location_name %in% us_states &
    sex_name != "Both" &
    metric_name == "Rate",
  .(state = location_name, year = as.integer(year),
    sex = sex_name, age_name,
    mort_rate = val, mort_rate_upper = upper, mort_rate_lower = lower)
]

add_age_cols(dt_mort)
dt_mort[, mx := mort_rate / 1e5]
dt_mort[, sex := factor(sex, levels = c("Male", "Female"))]
dt_mort[, age_group := factor(age_group, levels = unname(age_label_map))]

setkey(dt_mort, state, year, sex, age_group)

stopifnot(dt_mort[, uniqueN(state)] == 51L)
stopifnot(!anyNA(dt_mort$mort_rate))
stopifnot(dt_mort[, .N, .(state, year, sex, age_group)][N > 1, .N] == 0L)

saveRDS(dt_mort, paste0(wd_data, "state_age_sex_mortality_gbd.rds"))
rm(dt_mort)


# ==============================================================
# SECTION B: Cause-specific decomposition inputs
# ==============================================================

# ── B1. All-cause rates for all locations (states + WE) ──────
# Need both Rate (for mx) and Number (for death counts / residual).

dt_ac <- dt_allcause_raw[
  location_name %in% keep_locations & sex_name != "Both",
  .(location = location_name, year = as.integer(year),
    sex = sex_name, age_name, metric_name, val)
]
add_age_cols(dt_ac)

dt_ac_rate <- dt_ac[metric_name == "Rate",
  .(location, year, sex, age, mx_all = val / 1e5)]

dt_ac_deaths <- dt_ac[metric_name == "Number",
  .(location, year, sex, age, deaths_all = val)]

rm(dt_allcause_raw, dt_ac)


# ── B2. Read cause-specific mortality from all folders ───────

gbd_dirs <- c(
  paste0(wd_raw, "gbd/mortality/infectious_childhood/"),
  paste0(wd_raw, "gbd/mortality/ncd7_cvd-dm/"),
  paste0(wd_raw, "gbd/mortality/injuries_disorders/"),
  paste0(wd_raw, "gbd/mortality/ncd_infectious/"),
  paste0(wd_raw, "gbd/mortality/ncd_tobacco/")
)

dt_cause_raw <- rbindlist(lapply(gbd_dirs, read_gbd_folder),
                          use.names = TRUE, fill = TRUE)

dt_cs <- dt_cause_raw[
  location_name %in% keep_locations & sex_name != "Both",
  .(location = location_name, year = as.integer(year),
    sex = sex_name, age_name, cause_name, metric_name, val)
]
add_age_cols(dt_cs)

dt_cs_rate <- dt_cs[metric_name == "Rate",
  .(location, year, sex, age, cause_name, mx = val / 1e5)]

dt_cs_deaths <- dt_cs[metric_name == "Number",
  .(location, year, sex, age, cause_name, deaths = val)]

dt_cause <- merge(dt_cs_rate, dt_cs_deaths,
  by = c("location", "year", "sex", "age", "cause_name"),
  all = TRUE)

rm(dt_cause_raw, dt_cs, dt_cs_rate, dt_cs_deaths)


# ── B3. Cause mapping (Karlsson 2025) ────────────────────────

dt_map <- as.data.table(read_excel(
  paste0(wd_data, "Karlsson2025_GBD_US_mapping_final.xlsx"),
  sheet = "User_GBD_causes"
))

dt_map_clean <- dt_map[, .(
  cause_name     = GBD_cause_used,
  cause_group    = Karlsson_priority_condition,
  classification = Classification,
  karlsson_group = Karlsson_group
)]

rm(dt_map)


# ── B4. Handle Stroke aggregate ──────────────────────────────
# GBD may include "Stroke" alongside "Ischemic stroke" +
# "Intracerebral hemorrhage". Drop aggregate to avoid double-counting.

stroke_subs <- c("Ischemic stroke", "Intracerebral hemorrhage")
if (any(stroke_subs %in% dt_cause$cause_name)) {
  dt_cause <- dt_cause[cause_name != "Stroke"]
  dt_map_clean <- dt_map_clean[cause_name != "Stroke"]
  cat("INFO: Dropped 'Stroke' aggregate (subcauses present)\n")
} else if ("Stroke" %in% dt_cause$cause_name) {
  cat("INFO: Keeping 'Stroke' aggregate (no subcauses in data)\n")
}


# ── B5. Merge mapping and aggregate to cause_groups ──────────

dt_cause <- merge(dt_cause,
  dt_map_clean[, .(cause_name, cause_group)],
  by = "cause_name", all.x = TRUE)

unmatched <- dt_cause[is.na(cause_group), unique(cause_name)]
if (length(unmatched) > 0L) {
  cat("WARNING: Unmatched causes -> 'Other':",
      paste(unmatched, collapse = ", "), "\n")
  dt_cause[is.na(cause_group), cause_group := "Other"]
}

# Rates are additive across causes within the same population cell,
# so sum(cause-specific rates) = cause_group rate. This is equivalent
# to the weighted average: sum(deaths) / population.
dt_grouped <- dt_cause[,
  .(mx = sum(mx, na.rm = TRUE), deaths = sum(deaths, na.rm = TRUE)),
  by = .(location, year, sex, age, cause_group)
]

rm(dt_cause)


# ── B6. Residual "Other" category ────────────────────────────
# = all-cause rate minus sum of individually-tracked cause groups.
# Captures cancers, CVD subtypes, etc. not in the Karlsson framework.

dt_mapped_tot <- dt_grouped[,
  .(mx_mapped = sum(mx), deaths_mapped = sum(deaths)),
  by = .(location, year, sex, age)
]

dt_resid <- merge(dt_ac_rate, dt_mapped_tot,
  by = c("location", "year", "sex", "age"), all.x = TRUE)
dt_resid <- merge(dt_resid, dt_ac_deaths,
  by = c("location", "year", "sex", "age"), all.x = TRUE)

dt_resid[is.na(mx_mapped), mx_mapped := 0]
dt_resid[is.na(deaths_mapped), deaths_mapped := 0]
dt_resid[, `:=`(
  mx     = pmax(mx_all - mx_mapped, 0),
  deaths = pmax(deaths_all - deaths_mapped, 0)
)]

pct_other <- dt_resid[, median(mx / mx_all, na.rm = TRUE)]
cat(sprintf("INFO: Median share of 'Other' in total mortality: %.1f%%\n",
            100 * pct_other))

dt_other <- dt_resid[, .(location, year, sex, age,
                          cause_group = "Other", mx, deaths)]

dt_full <- rbindlist(list(dt_grouped, dt_other), use.names = TRUE)

rm(dt_grouped, dt_mapped_tot, dt_resid, dt_other, dt_ac_rate, dt_ac_deaths)


# ── B7. Complete grid ────────────────────────────────────────
# Fill absent age x cause_group cells with 0 so every location
# has the same rectangular structure for decomposition.

all_cg <- sort(unique(dt_full$cause_group))

grid <- CJ(
  location    = unique(dt_full$location),
  year        = unique(dt_full$year),
  sex         = unique(dt_full$sex),
  age         = unique(dt_full$age),
  cause_group = all_cg
)

dt_full <- merge(grid, dt_full, by = names(grid), all.x = TRUE)
dt_full[is.na(mx), mx := 0]
dt_full[is.na(deaths), deaths := 0]

rm(grid)


# ── B8. Defensive checks ────────────────────────────────────

stopifnot(!anyNA(dt_full[, .(location, year, sex, age, cause_group)]))
stopifnot(dt_full[, .N, .(location, year, sex, age, cause_group)][N > 1, .N] == 0L)
stopifnot(all(is.finite(dt_full$mx)))
stopifnot(all(dt_full$mx >= 0))


# ── B9. Split: state data + references ───────────────────────

dt_state_cause <- dt_full[location %in% us_states]
setnames(dt_state_cause, "location", "state")

dt_ref_we <- dt_full[location == "Western Europe"]
dt_ref_we[, location := NULL]

# Best-3 states: average rates of the 3 US states with the lowest
# PPD per year x sex. Uses all-cause rates for ranking (not per-cause).

ppd_rank_fn <- function(mx_vec, age_vec) {
  keep <- age_vec < 70L
  mx_vec <- mx_vec[keep]; age_vec <- age_vec[keep]
  n  <- fifelse(age_vec == 0L, 1, fifelse(age_vec == 1L, 1,
        fifelse(age_vec == 2L, 3, 5)))
  ax <- fifelse(age_vec == 0L, 0.1, n / 2)
  qx <- (n * mx_vec) / (1 + (n - ax) * mx_vec)
  qx <- pmin(pmax(qx, 0), 1)
  1 - prod(1 - qx)
}

dt_state_ac <- dt_state_cause[,
  .(mx_all = sum(mx)),
  by = .(state, year, sex, age)
]

dt_ppd <- dt_state_ac[,
  .(ppd = ppd_rank_fn(mx_all, age)),
  by = .(state, year, sex)
]

dt_ppd[, rnk := frank(ppd, ties.method = "first"), by = .(year, sex)]
dt_best3_ids <- dt_ppd[rnk <= 3L, .(state, year, sex)]

cat("\nINFO: Best-3 states (latest year):\n")
print(dt_best3_ids[year == max(year)])

dt_ref_b3 <- merge(dt_state_cause, dt_best3_ids,
  by = c("state", "year", "sex")
)[,
  .(mx = mean(mx), deaths = mean(deaths)),
  by = .(year, sex, age, cause_group)
]

rm(dt_full, dt_state_ac, dt_ppd, dt_best3_ids)


# ── B10. Save outputs ────────────────────────────────────────

saveRDS(dt_state_cause, paste0(wd_data, "mx_state_cause.rds"))
saveRDS(dt_ref_we,      paste0(wd_data, "mx_ref_western_europe.rds"))
saveRDS(dt_ref_b3,      paste0(wd_data, "mx_ref_local_best3.rds"))
saveRDS(dt_map_clean,   paste0(wd_data, "cause_mapping_clean.rds"))


# ── B11. Diagnostics ─────────────────────────────────────────

cat("\n=== OUTPUT SUMMARY ===\n")
cat(sprintf(
  "mx_state_cause:         %d rows, %d states, %d cause groups, years %d-%d\n",
  nrow(dt_state_cause), dt_state_cause[, uniqueN(state)],
  dt_state_cause[, uniqueN(cause_group)],
  min(dt_state_cause$year), max(dt_state_cause$year)))
cat(sprintf("mx_ref_western_europe:  %d rows\n", nrow(dt_ref_we)))
cat(sprintf("mx_ref_local_best3:     %d rows\n", nrow(dt_ref_b3)))
cat(sprintf(
  "cause_mapping_clean:    %d entries -> %d cause groups\n",
  nrow(dt_map_clean), dt_map_clean[, uniqueN(cause_group)]))
cat("Cause groups: ", paste(all_cg, collapse = ", "), "\n")

rm(dt_state_cause, dt_ref_we, dt_ref_b3, dt_map_clean, all_cg)
