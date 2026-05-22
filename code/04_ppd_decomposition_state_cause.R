# ============================================================
# 04_ppd_decomposition_state_cause.R
# Cause-specific PPD decomposition comparing each US state to
# two reference populations, using:
#   (1) Stepwise replacement  (Andreev, Shkolnikov, Begun 2002)
#   (2) Horiuchi continuous-change (Horiuchi, Wilmoth, Pletcher 2008)
#
# Adapted from Karlsson et al. (2025) for Premature Potential
# Death (PPD = 70q0) instead of life expectancy.
#
# Inputs  (from wd_data, produced by 02_load_inputs.R):
#   mx_state_cause.rds, mx_ref_western_europe.rds,
#   mx_ref_local_best3.rds
#
# Outputs (to wd_outp):
#   decomp_state_cause_stepwise.csv
#   decomp_state_cause_horiuchi.csv
#   decomp_state_cause_combined.csv
#   priority_conditions_by_state.csv
# ============================================================

library(data.table)


# ── Parameters ───────────────────────────────────────────────

analysis_year <- 2019L
age_cutoff    <- 70L
horiuchi_N    <- 20L    # integration steps for Horiuchi method


# ══════════════════════════════════════════════════════════════
# 1. Age structure constants (abridged life table below age 70)
# ══════════════════════════════════════════════════════════════

AGES   <- c(0L, 1L, 2L, 5L, 10L, 15L, 20L, 25L, 30L, 35L,
            40L, 45L, 50L, 55L, 60L, 65L)
WIDTHS <- c(1, 1, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5)
AX     <- c(0.1, 0.5, 1.5, rep(2.5, 13))
N_AGES <- length(AGES)

# N_CAUSES set after loading data (depends on number of cause_groups)


# ══════════════════════════════════════════════════════════════
# 2. PPD function
# ══════════════════════════════════════════════════════════════
# Takes a flat rate vector of length N_AGES * N_CAUSES, ordered
# cause-within-age: [age0_c1, age0_c2, ..., age1_c1, ...].
# Sums across causes to get all-cause mx, then applies the
# abridged life table formula: qx = n*mx / (1 + (n - ax)*mx).
# Returns PPD = 1 - prod(1 - qx).

compute_ppd <- function(rate_vec) {
  # .colSums treats vector as N_CAUSES-row x N_AGES-col matrix
  mx_all <- pmax(.colSums(rate_vec, N_CAUSES, N_AGES), 0)
  qx <- (WIDTHS * mx_all) / (1 + (WIDTHS - AX) * mx_all)
  qx <- pmin(pmax(qx, 0), 1)
  1 - prod(1 - qx)
}


# ══════════════════════════════════════════════════════════════
# 3. Unit test: PPD function
# ══════════════════════════════════════════════════════════════

cat("\n=== Unit tests ===\n")

# Toy: 2 ages (width 5 each, ax = 2.5), 2 causes, threshold 10
# Flat rate mx = 0.01 per person at both ages
# qx = 5 * 0.01 / (1 + 2.5 * 0.01) = 0.05 / 1.025 = 0.04878049
# PPD = 1 - (1 - qx)^2 = 0.09518147

toy_n_causes <- 2L
toy_n_ages   <- 2L
toy_widths   <- c(5, 5)
toy_ax       <- c(2.5, 2.5)

ppd_toy <- function(rv) {
  mx_all <- pmax(.colSums(rv, toy_n_causes, toy_n_ages), 0)
  qx <- (toy_widths * mx_all) / (1 + (toy_widths - toy_ax) * mx_all)
  qx <- pmin(pmax(qx, 0), 1)
  1 - prod(1 - qx)
}

# Each cause contributes 0.005 -> total 0.01 per age
test_vec <- rep(0.005, 4)
qx_expected <- 5 * 0.01 / (1 + 2.5 * 0.01)
ppd_expected <- 1 - (1 - qx_expected)^2
ppd_result <- ppd_toy(test_vec)

cat(sprintf("  PPD flat-rate test: expected %.8f, got %.8f (diff %.1e)\n",
            ppd_expected, ppd_result, abs(ppd_expected - ppd_result)))
stopifnot(abs(ppd_result - ppd_expected) < 1e-10)
cat("  PASSED\n")


# ══════════════════════════════════════════════════════════════
# 4. Decomposition algorithms
# ══════════════════════════════════════════════════════════════

# ── 4a. Stepwise replacement (Andreev et al. 2002) ───────────
# Forward: sequentially replace state rates with reference,
#   cells 1 -> K. Each cell's contribution = PPD before vs after.
# Backward: same but cells K -> 1.
# Final contribution = average of forward and backward.
# Both directions sum exactly to the total PPD gap.

stepwise_decompose <- function(state_vec, ref_vec, ppd_fn) {
  K <- length(state_vec)

  # Forward: replace left to right
  contrib_fwd <- numeric(K)
  current <- state_vec
  for (i in seq_len(K)) {
    ppd_before <- ppd_fn(current)
    current[i] <- ref_vec[i]
    contrib_fwd[i] <- ppd_before - ppd_fn(current)
  }

  # Backward: replace right to left
  contrib_bwd <- numeric(K)
  current <- state_vec
  for (i in rev(seq_len(K))) {
    ppd_before <- ppd_fn(current)
    current[i] <- ref_vec[i]
    contrib_bwd[i] <- ppd_before - ppd_fn(current)
  }

  (contrib_fwd + contrib_bwd) / 2
}


# ── 4b. Horiuchi continuous-change (2008) ────────────────────
# Linearly interpolate from reference to state in N steps.
# At each step, approximate the gradient by central differences
# using the step-size as the perturbation (matching DemoDecomp).
# Contribution_i = sum over steps of [F(r + eps/2) - F(r - eps/2)].

horiuchi_decompose <- function(state_vec, ref_vec, ppd_fn, N = 20L) {
  K <- length(state_vec)
  delta   <- state_vec - ref_vec
  epsilon <- delta / N

  contributions <- numeric(K)
  nonzero <- which(abs(delta) > .Machine$double.eps)
  if (length(nonzero) == 0L) return(contributions)

  for (j in seq_len(N)) {
    base <- ref_vec + (j - 0.5) * epsilon
    for (i in nonzero) {
      r_up      <- base; r_up[i] <- base[i] + epsilon[i] / 2
      r_dn      <- base; r_dn[i] <- base[i] - epsilon[i] / 2
      contributions[i] <- contributions[i] + ppd_fn(r_up) - ppd_fn(r_dn)
    }
  }

  contributions
}


# ══════════════════════════════════════════════════════════════
# 5. Toy example verification
# ══════════════════════════════════════════════════════════════

# 2 ages (5, 10), 2 causes (A, B), threshold 15
# Rate vector order: [age5_A, age5_B, age10_A, age10_B]
toy_state <- c(0.03, 0.04, 0.05, 0.06)
toy_ref   <- c(0.01, 0.02, 0.02, 0.03)

ppd_s <- ppd_toy(toy_state)
ppd_r <- ppd_toy(toy_ref)
gap   <- ppd_s - ppd_r
cat(sprintf("\n  Toy PPD: state = %.6f, ref = %.6f, gap = %.6f\n",
            ppd_s, ppd_r, gap))

# Stepwise
c_step <- stepwise_decompose(toy_state, toy_ref, ppd_toy)
cat(sprintf("  Stepwise contributions: %s\n",
            paste(sprintf("%.6f", c_step), collapse = ", ")))
cat(sprintf("  Stepwise sum = %.8f vs gap = %.8f (diff %.1e)\n",
            sum(c_step), gap, abs(sum(c_step) - gap)))
stopifnot(abs(sum(c_step) - gap) < 1e-10)

# Horiuchi (N=100 for precise toy test)
c_hori <- horiuchi_decompose(toy_state, toy_ref, ppd_toy, N = 100L)
cat(sprintf("  Horiuchi contributions: %s\n",
            paste(sprintf("%.6f", c_hori), collapse = ", ")))
cat(sprintf("  Horiuchi sum = %.8f vs gap = %.8f (diff %.1e)\n",
            sum(c_hori), gap, abs(sum(c_hori) - gap)))
stopifnot(abs(sum(c_hori) - gap) < 1e-6)

# Cross-method agreement
max_diff <- max(abs(c_step - c_hori))
cat(sprintf("  Max stepwise-Horiuchi cell diff: %.2e (%.2f%% of gap)\n",
            max_diff, 100 * max_diff / gap))
cat("  Toy tests PASSED\n\n")


# ══════════════════════════════════════════════════════════════
# 6. Load data
# ══════════════════════════════════════════════════════════════

dt_state  <- readRDS(paste0(wd_data, "mx_state_cause.rds"))
dt_ref_we <- readRDS(paste0(wd_data, "mx_ref_western_europe.rds"))
dt_ref_b3 <- readRDS(paste0(wd_data, "mx_ref_local_best3.rds"))

# Filter to analysis year and ages below cutoff
dt_state  <- dt_state[year == analysis_year & age < age_cutoff]
dt_ref_we <- dt_ref_we[year == analysis_year & age < age_cutoff]
dt_ref_b3 <- dt_ref_b3[year == analysis_year & age < age_cutoff]

# Verify age and cause_group alignment
ages_used   <- sort(unique(dt_state$age))
causes_used <- sort(unique(dt_state$cause_group))
N_CAUSES    <- length(causes_used)

stopifnot(identical(ages_used, AGES))
stopifnot(setequal(unique(dt_ref_we$cause_group), causes_used))
stopifnot(setequal(unique(dt_ref_b3$cause_group), causes_used))

states_list <- sort(unique(dt_state$state))
sexes_list  <- c("Male", "Female")
refs_list   <- c("western_europe", "local_best3")

cat(sprintf("Decomposition setup: %d states x %d sexes x %d refs\n",
            length(states_list), length(sexes_list), length(refs_list)))
cat(sprintf("  %d ages x %d cause groups = %d cells per rate vector\n",
            N_AGES, N_CAUSES, N_AGES * N_CAUSES))


# ── Helper: data.table -> rate vector ────────────────────────
# Expects dt with columns: age, cause_group, mx
# Returns vector ordered cause-within-age (matching compute_ppd layout)

to_rate_vec <- function(dt) {
  dt_wide <- dcast(dt, age ~ cause_group, value.var = "mx", fill = 0)
  setorder(dt_wide, age)
  as.vector(t(as.matrix(dt_wide[, causes_used, with = FALSE])))
}


# ══════════════════════════════════════════════════════════════
# 7. Full pipeline
# ══════════════════════════════════════════════════════════════

# Pre-compute reference rate vectors (same for all states)
ref_vecs <- list(
  western_europe = list(
    Male   = to_rate_vec(dt_ref_we[sex == "Male"]),
    Female = to_rate_vec(dt_ref_we[sex == "Female"])
  ),
  local_best3 = list(
    Male   = to_rate_vec(dt_ref_b3[sex == "Male"]),
    Female = to_rate_vec(dt_ref_b3[sex == "Female"])
  )
)

combos <- CJ(state = states_list, sex = sexes_list, reference = refs_list,
             sorted = FALSE)
n_combos <- nrow(combos)

cat(sprintf("Running %d decompositions...\n", n_combos))

results <- vector("list", n_combos)

for (idx in seq_len(n_combos)) {
  s   <- combos$state[idx]
  sx  <- combos$sex[idx]
  ref <- combos$reference[idx]

  if (idx %% 20 == 0L || idx == n_combos)
    cat(sprintf("  %d / %d\n", idx, n_combos))

  # State rate vector
  vec_state <- to_rate_vec(dt_state[state == s & sex == sx])
  vec_ref   <- ref_vecs[[ref]][[sx]]

  ppd_state <- compute_ppd(vec_state)
  ppd_ref   <- compute_ppd(vec_ref)

  # Stepwise decomposition
  c_step <- stepwise_decompose(vec_state, vec_ref, compute_ppd)

  # Horiuchi decomposition
  c_hori <- horiuchi_decompose(vec_state, vec_ref, compute_ppd, N = horiuchi_N)

  # Build result table: age x cause_group
  dt_res <- data.table(
    state       = s,
    sex         = sx,
    reference   = ref,
    age         = rep(ages_used, each = N_CAUSES),
    cause_group = rep(causes_used, times = N_AGES),
    ppd_state   = ppd_state,
    ppd_ref     = ppd_ref,
    ppd_gap     = ppd_state - ppd_ref,
    contrib_stepwise = c_step,
    contrib_horiuchi = c_hori
  )

  results[[idx]] <- dt_res
}

dt_all <- rbindlist(results)
rm(results)

cat("Decompositions complete.\n")


# ══════════════════════════════════════════════════════════════
# 8. Reconciliation check
# ══════════════════════════════════════════════════════════════
# Sum of cell contributions should equal total PPD gap.

dt_recon <- dt_all[,
  .(sum_stepwise = sum(contrib_stepwise),
    sum_horiuchi = sum(contrib_horiuchi),
    ppd_gap      = ppd_gap[1]),
  by = .(state, sex, reference)
]

dt_recon[, `:=`(
  pct_err_step = 100 * abs(sum_stepwise - ppd_gap) / abs(ppd_gap),
  pct_err_hori = 100 * abs(sum_horiuchi - ppd_gap) / abs(ppd_gap)
)]

cat("\n=== Reconciliation ===\n")
cat(sprintf("  Stepwise: max error = %.4f%%\n", max(dt_recon$pct_err_step)))
cat(sprintf("  Horiuchi: max error = %.4f%%\n", max(dt_recon$pct_err_hori)))

bad <- dt_recon[pct_err_step > 0.1 | pct_err_hori > 0.1]
if (nrow(bad) > 0L) {
  cat("  WARNING: cases with >0.1% reconciliation error:\n")
  print(bad)
} else {
  cat("  All within 0.1% tolerance.\n")
}


# ══════════════════════════════════════════════════════════════
# 9. Reshape into method-specific and combined outputs
# ══════════════════════════════════════════════════════════════

common_cols <- c("state", "sex", "reference", "age", "cause_group",
                 "ppd_state", "ppd_ref", "ppd_gap")

dt_stepwise <- dt_all[, c(common_cols, "contrib_stepwise"), with = FALSE]
setnames(dt_stepwise, "contrib_stepwise", "contribution")
dt_stepwise[, method := "stepwise"]

dt_horiuchi <- dt_all[, c(common_cols, "contrib_horiuchi"), with = FALSE]
setnames(dt_horiuchi, "contrib_horiuchi", "contribution")
dt_horiuchi[, method := "horiuchi"]

dt_combined <- rbindlist(list(dt_stepwise, dt_horiuchi))


# ══════════════════════════════════════════════════════════════
# 10. Priority conditions summary
# ══════════════════════════════════════════════════════════════
# Aggregate contributions across ages per cause_group,
# rank by absolute contribution, and show top 5 per state.

dt_cause_totals <- dt_combined[,
  .(contribution = sum(contribution),
    ppd_gap      = ppd_gap[1]),
  by = .(state, sex, reference, method, cause_group)
]

dt_cause_totals[, contribution_pct := 100 * contribution / ppd_gap]

dt_cause_totals[, rnk := frank(-abs(contribution), ties.method = "first"),
                by = .(state, sex, reference, method)]

dt_priority <- dt_cause_totals[rnk <= 5L]
setorder(dt_priority, state, sex, reference, method, rnk)

cat("\n=== Priority conditions (example: first state, Male, Horiuchi) ===\n")
example_state <- states_list[1]
print(dt_priority[state == example_state & sex == "Male" &
                    reference == "western_europe" & method == "horiuchi",
                  .(cause_group, contribution, contribution_pct, rnk)])


# ══════════════════════════════════════════════════════════════
# 11. Save outputs
# ══════════════════════════════════════════════════════════════

fwrite(dt_stepwise, paste0(wd_outp, "decomp_state_cause_stepwise.csv"))
fwrite(dt_horiuchi, paste0(wd_outp, "decomp_state_cause_horiuchi.csv"))
fwrite(dt_combined, paste0(wd_outp, "decomp_state_cause_combined.csv"))
fwrite(dt_priority, paste0(wd_outp, "priority_conditions_by_state.csv"))

cat("\nOutputs saved to: ", wd_outp, "\n")


# ══════════════════════════════════════════════════════════════
# 12. Final reconciliation table
# ══════════════════════════════════════════════════════════════

cat("\n=== Final reconciliation table (sample) ===\n")
cat("Total PPD gap vs sum of decomposed contributions:\n\n")
print(head(dt_recon[order(-abs(ppd_gap))], 20))

rm(dt_all, dt_stepwise, dt_horiuchi, dt_combined,
   dt_cause_totals, dt_priority, dt_recon,
   ref_vecs, combos)
