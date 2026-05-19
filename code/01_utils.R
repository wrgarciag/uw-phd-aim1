# Age Categories GBD-----

# Vectorized age‐grouping function
create_age_groups <- function(age) {
  # define breaks and labels
  breaks <- c(20, seq(25, 85, by = 5), Inf)
  labels <- c(
    paste0(seq(20, 80, by = 5), "-", seq(24, 84, by = 5)),
    "85plus"
  )
  
  # cut into factor
  cut(
    x              = age,
    breaks         = breaks,
    labels         = labels,
    right          = FALSE,
    include.lowest = TRUE
  )
}