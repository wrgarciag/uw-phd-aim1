# ============================================================
# 04_ppd_decomposition_state_cause.R
# State-age-sex only, with global best-country benchmark option
# ============================================================

library(data.table)

age_cutoff <- 70
analysis_year <- 2019

benchmark_type <- "best_country_world"
# Options:
#   "best_state"
#   "top_decile_states"
#   "us_national"
#   "best_country_world"

dt_cause <- fread("data/processed/state_cause_specific_mortality.csv")
# Expected: state, year, sex, age, cause, mx_cause

dt_cause <- dt_cause[
  year == analysis_year &
    age >= 0 & age < age_cutoff
]

cause_map <- data.table(
  cause = c(
    "ischemic_heart_disease",
    "ischemic_stroke",
    "hemorrhagic_stroke",
    "diabetes",
    "lung_cancer",
    "copd",
    "road_injury",
    "suicide",
    "drug_overdose",
    "homicide",
    "other"
  ),
  cause_group = c(
    "Atherosclerotic CVD",
    "Atherosclerotic CVD",
    "Hemorrhagic stroke",
    "Diabetes",
    "Tobacco-related NCD",
    "Tobacco-related NCD",
    "Road injury",
    "Suicide",
    "Drug overdose",
    "Violence",
    "Other"
  )
)

dt_cause <- merge(dt_cause, cause_map, by = "cause", all.x = TRUE)
dt_cause[is.na(cause_group), cause_group := "Other"]

dt_decomp_input <- dt_cause[
  ,
  .(mx_cause = sum(mx_cause, na.rm = TRUE)),
  by = .(state, year, sex, age, cause_group)
]

dt_all <- dt_decomp_input[
  ,
  .(mx_all = sum(mx_cause, na.rm = TRUE)),
  by = .(state, year, sex, age)
]

estimate_ppd <- function(dt_age_mx) {
  tmp <- copy(dt_age_mx)
  setorder(tmp, age)

  tmp[, ax := fifelse(age == 0, 0.1, 0.5)]
  tmp[, qx := mx_all / (1 + (1 - ax) * mx_all)]
  tmp[, qx := pmin(pmax(qx, 0), 1)]
  tmp[, px := 1 - qx]

  1 - prod(tmp$px)
}

dt_ppd_state <- dt_all[
  ,
  .(ppd = estimate_ppd(.SD)),
  by = .(state, sex),
  .SDcols = c("age", "mx_all")
]

if (benchmark_type == "best_state") {

  dt_best <- dt_ppd_state[
    ,
    .SD[which.min(ppd)],
    by = sex
  ][, .(sex, benchmark_state = state)]

  dt_bench_cause <- merge(
    dt_decomp_input,
    dt_best,
    by.x = c("state", "sex"),
    by.y = c("benchmark_state", "sex")
  )

} else if (benchmark_type == "us_national") {

  dt_bench_cause <- fread("data/processed/us_national_cause_mx.csv")

  dt_bench_cause <- dt_bench_cause[
    year == analysis_year &
      age >= 0 & age < age_cutoff
  ]

} else if (benchmark_type == "top_decile_states") {

  stop("Add top-decile state benchmark construction here.")

} else if (benchmark_type == "best_country_world") {

  dt_world <- fread("data/processed/world_country_cause_specific_mortality.csv")

  dt_world <- dt_world[
    year == analysis_year &
      age >= 0 & age < age_cutoff
  ]

  dt_world_all <- dt_world[
    ,
    .(mx_all = sum(mx_cause, na.rm = TRUE)),
    by = .(country, year, sex, age)
  ]

  dt_ppd_country <- dt_world_all[
    ,
    .(ppd = estimate_ppd(.SD)),
    by = .(country, sex),
    .SDcols = c("age", "mx_all")
  ]

  dt_best_country <- dt_ppd_country[
    ,
    .SD[which.min(ppd)],
    by = sex
  ][, .(sex, benchmark_country = country)]

  dt_bench_cause <- merge(
    dt_world,
    dt_best_country,
    by.x = c("country", "sex"),
    by.y = c("benchmark_country", "sex")
  )
}

dt_bench_cause <- dt_bench_cause[
  ,
  .(age, sex, cause_group, mx_cause_bench = mx_cause)
]

make_ppd_from_cause_rates <- function(dt_rates) {
  tmp <- dt_rates[
    ,
    .(mx_all = sum(mx_cause, na.rm = TRUE)),
    by = age
  ]
  estimate_ppd(tmp)
}

decompose_state_ppd <- function(state_i, sex_i) {

  target <- dt_decomp_input[
    state == state_i & sex == sex_i
  ]

  bench <- dt_bench_cause[
    sex == sex_i,
    .(age, cause_group, mx_cause_bench)
  ]

  dat <- merge(
    target,
    bench,
    by = c("age", "cause_group"),
    all.x = TRUE
  )

  dat[is.na(mx_cause_bench), mx_cause_bench := 0]

  ppd_target <- make_ppd_from_cause_rates(
    dat[, .(age, cause_group, mx_cause)]
  )

  ppd_benchmark <- make_ppd_from_cause_rates(
    dat[, .(age, cause_group, mx_cause = mx_cause_bench)]
  )

  total_gap <- ppd_target - ppd_benchmark

  causes <- sort(unique(dat$cause_group))

  rbindlist(lapply(causes, function(cg) {

    cf <- copy(dat)
    cf[cause_group == cg, mx_cause := mx_cause_bench]

    ppd_cf <- make_ppd_from_cause_rates(
      cf[, .(age, cause_group, mx_cause)]
    )

    contribution <- ppd_target - ppd_cf

    data.table(
      state = state_i,
      sex = sex_i,
      benchmark_type = benchmark_type,
      cause_group = cg,
      ppd_target = ppd_target,
      ppd_benchmark = ppd_benchmark,
      total_ppd_gap = total_gap,
      contribution_ppd = contribution,
      contribution_pct = 100 * contribution / total_gap
    )
  }))
}

state_grid <- unique(dt_ppd_state[, .(state, sex)])

dt_ppd_decomp <- rbindlist(
  lapply(seq_len(nrow(state_grid)), function(i) {
    decompose_state_ppd(
      state_i = state_grid$state[i],
      sex_i = state_grid$sex[i]
    )
  }),
  fill = TRUE
)

dt_ppd_decomp[, priority_group := fifelse(
  cause_group %in% c(
    "Atherosclerotic CVD",
    "Hemorrhagic stroke",
    "Diabetes",
    "Tobacco-related NCD",
    "Road injury",
    "Suicide"
  ),
  "NCD-7 adapted",
  fifelse(
    cause_group %in% c("Drug overdose", "Violence"),
    "US-specific priority",
    "Other"
  )
)]

dt_summary <- dt_ppd_decomp[
  ,
  .(
    contribution_ppd = sum(contribution_ppd, na.rm = TRUE),
    total_ppd_gap = unique(total_ppd_gap)
  ),
  by = .(state, sex, benchmark_type, priority_group)
]

dt_summary[, contribution_pct := 100 * contribution_ppd / total_ppd_gap]

fwrite(dt_ppd_decomp, "output/ppd_decomposition_state_sex_cause.csv")
fwrite(dt_summary, "output/ppd_decomposition_state_sex_priority_groups.csv")
