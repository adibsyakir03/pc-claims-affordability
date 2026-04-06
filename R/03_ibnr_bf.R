# ============================================================
#  PHASE 3 — SCRIPT 3: BORNHUETTER-FERGUSON IBNR
#  File    : r/03_ibnr_bf.R
#  Purpose : Estimate IBNR using Bornhuetter-Ferguson method
#            BF combines actual development with expected losses
#            More stable than chain-ladder for immature years
#  Run in  : RStudio
# ============================================================

# ------------------------------------------------------------
# STEP 1 — LOAD LIBRARIES
# ------------------------------------------------------------
library(ChainLadder)
library(DBI)
library(RMySQL)
library(dplyr)
library(ggplot2)
library(scales)
library(readr)

# ------------------------------------------------------------
# STEP 2 — CONNECT AND PULL DATA
# ------------------------------------------------------------
con <- dbConnect(
  RMySQL::MySQL(),
  host     = "localhost",
  port     = 3306,
  dbname   = "cas_pc_analysis",
  user     = "root",
  password = "Actuary123"
)

# Pull triangle data
triangle_raw <- dbGetQuery(con, "
  SELECT * FROM v_loss_triangle
  ORDER BY AccidentYear
")

# Pull premium by accident year for BF expected losses
premium_data <- dbGetQuery(con, "
  SELECT
    AccidentYear,
    SUM(EarnedPremNet_B) AS earned_premium
  FROM ppauto
  WHERE Single = 1
  AND EarnedPremNet_B > 0
  AND DevelopmentLag = 10
  GROUP BY AccidentYear
  ORDER BY AccidentYear
")

# Pull industry summary for loss ratios
industry_summary <- dbGetQuery(con, "
  SELECT * FROM v_industry_summary
  ORDER BY AccidentYear
")

dbDisconnect(con)
cat("Data pulled successfully\n")

# ------------------------------------------------------------
# STEP 3 — BUILD UPPER TRIANGLE
# Simulate mid-development position as at year-end 2004
# This means AY1998 has 7 lags, AY2004 has 1 lag
# BF is most useful for immature years — this demonstrates it
# ------------------------------------------------------------

triangle_matrix <- triangle_raw %>%
  select(-AccidentYear) %>%
  as.matrix()

rownames(triangle_matrix) <- triangle_raw$AccidentYear

# Create upper triangle as at year-end 2004
upper_triangle <- triangle_matrix
for (i in 1:nrow(upper_triangle)) {
  acc_year <- as.integer(rownames(upper_triangle)[i])
  for (j in 1:ncol(upper_triangle)) {
    dev_year <- acc_year + j - 1
    if (dev_year > 2004) {
      upper_triangle[i, j] <- NA
    }
  }
}

cat("\nUpper triangle as at year-end 2004:\n")
print(upper_triangle)

paid_triangle <- as.triangle(upper_triangle)

# ------------------------------------------------------------
# STEP 4 — DEFINE EXPECTED LOSS RATIOS FOR BF
# BF formula: IBNR = Expected Ultimate × (1 - % Developed)
# Expected ultimate = Earned Premium × Expected Loss Ratio
#
# We use the industry average paid loss ratio from fully
# developed years (1998-2001) as our a priori expected LR
# These are the years we can observe at full development
# ------------------------------------------------------------

# Calculate a priori expected loss ratio
# Use average of fully developed years 1998-2001
fully_dev_years <- industry_summary %>%
  filter(AccidentYear <= 2001)

apriori_lr <- mean(fully_dev_years$paid_loss_ratio) / 100

cat(sprintf("\nA priori expected loss ratio: %.1f%%\n",
    apriori_lr * 100))
cat("(Based on average of fully developed AYs 1998-2001)\n")

# Expected ultimate losses = premium × a priori loss ratio
expected_ultimates <- premium_data$earned_premium * apriori_lr

cat("\nExpected ultimate losses by accident year:\n")
for (i in 1:nrow(premium_data)) {
  cat(sprintf("  AY%d: Premium=%s × LR=%.1f%% = Expected Ultimate=%s\n",
      premium_data$AccidentYear[i],
      format(round(premium_data$earned_premium[i], 0), big.mark=","),
      apriori_lr * 100,
      format(round(expected_ultimates[i], 0), big.mark=",")))
}

# STEP 5 — RUN BORNHUETTER-FERGUSON METHOD
# ------------------------------------------------------------

# Calculate CDFs directly from link ratios
# rather than re-running MackChainLadder on upper triangle
link_ratios_raw <- attr(ata(paid_triangle), "vwtd")

# Remove NA link ratios
link_ratios_clean <- link_ratios_raw[!is.na(link_ratios_raw)]

# Calculate CDFs — multiply from right to left
n <- length(link_ratios_clean)
cdfs_full <- numeric(n)
cdfs_full[n] <- link_ratios_clean[n]
for (i in (n-1):1) {
  cdfs_full[i] <- link_ratios_clean[i] * cdfs_full[i+1]
}

# % developed = 1 / CDF
pct_developed <- 1 / cdfs_full

# Match to accident years — later years have lower % developed
# AY1998 is most developed, AY2004 is least developed
n_years <- nrow(premium_data)
cdfs_by_year <- rep(1.0, n_years)
cdfs_by_year[1:length(pct_developed)] <- pct_developed

# For years beyond available CDFs set to 1.0 (fully developed)
cdfs_by_year[cdfs_by_year > 1] <- 1.0

cat("\nDevelopment % by accident year (as at 2004):\n")
for (i in 1:length(cdfs_by_year)) {
  cat(sprintf("  AY%d: %.1f%% developed\n",
              premium_data$AccidentYear[i],
              cdfs_by_year[i] * 100))
}

# BF IBNR = Expected Ultimate x (1 - % Developed)
bf_ibnr    <- expected_ultimates * (1 - cdfs_by_year)
paid_to_date <- apply(upper_triangle, 1,
                      function(x) max(x[!is.na(x)]))
bf_ultimate  <- paid_to_date + bf_ibnr

# STEP 6 — COMPARE CHAIN-LADDER VS BF
# ------------------------------------------------------------

# CL IBNR = use same CDFs but purely from development
# without the a priori expected loss ratio blend
cl_ibnr <- expected_ultimates * (1 - cdfs_by_year) *
  (paid_to_date / expected_ultimates)

comparison <- data.frame(
  AccidentYear = premium_data$AccidentYear,
  PctDeveloped = round(cdfs_by_year * 100, 1),
  CL_IBNR      = round(cl_ibnr, 0),
  BF_IBNR      = round(bf_ibnr, 0),
  Difference   = round(bf_ibnr - cl_ibnr, 0)
)

cat("\n--- CHAIN-LADDER vs BORNHUETTER-FERGUSON ---\n")
print(comparison)

cat("\nKey insight: BF gives more stable estimates for\n")
cat("immature years (low % developed) because it\n")
cat("blends actual experience with expected losses.\n")

# Build BF summary table
bf_summary <- data.frame(
  AccidentYear  = premium_data$AccidentYear,
  EarnedPremium = round(premium_data$earned_premium, 0),
  PaidToDate    = round(paid_to_date, 0),
  PctDeveloped  = round(cdfs_by_year * 100, 1),
  ExpectedUlt   = round(expected_ultimates, 0),
  BF_IBNR       = round(bf_ibnr, 0),
  BF_Ultimate   = round(bf_ultimate, 0),
  BF_LossRatio  = round(bf_ultimate /
                          premium_data$earned_premium * 100, 1)
)

cat("\n--- BORNHUETTER-FERGUSON RESULTS ---\n")
print(bf_summary)

cat(sprintf("\nTotal BF IBNR estimate: %s\n",
            format(sum(bf_summary$BF_IBNR), big.mark = ",")))
cat(sprintf("Total BF ultimate losses: %s\n",
            format(sum(bf_summary$BF_Ultimate), big.mark = ",")))
cat(sprintf("Overall BF loss ratio: %.1f%%\n",
            sum(bf_summary$BF_Ultimate) /
              sum(bf_summary$EarnedPremium) * 100))

# ------------------------------------------------------------
# STEP 7 — RESERVE ADEQUACY TEST
# Compare BF ultimate to premium — can it be funded?
# ------------------------------------------------------------

bf_summary <- bf_summary %>%
  mutate(
    FundingGap = EarnedPremium - BF_Ultimate -
                 round(EarnedPremium * 0.285, 0),
    ReserveAdequacy = case_when(
      FundingGap >= 0  ~ "ADEQUATE",
      FundingGap < 0   ~ "INADEQUATE"
    )
  )

cat("\n--- RESERVE ADEQUACY (BF BASIS) ---\n")
print(bf_summary %>%
        select(AccidentYear, EarnedPremium,
               BF_Ultimate, FundingGap, ReserveAdequacy))

# ------------------------------------------------------------
# STEP 8 — VISUALISE BF RESULTS
# ------------------------------------------------------------

# Plot 1 — BF IBNR by accident year
p1 <- ggplot(bf_summary,
       aes(x = factor(AccidentYear), y = BF_IBNR,
           fill = ReserveAdequacy)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = c("ADEQUATE"   = "#1D9E75",
                               "INADEQUATE" = "#D85A30")) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Bornhuetter-Ferguson IBNR estimates by accident year",
    subtitle = "As at year-end 2004 — green = adequate reserves, red = inadequate",
    x        = "Accident year",
    y        = "BF IBNR estimate ($000s)",
    fill     = "Reserve adequacy"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10),
    legend.position = "top"
  )

ggsave("outputs/charts/04_bf_ibnr.png",
       p1, width = 10, height = 6, dpi = 150)
cat("\nChart saved: 04_bf_ibnr.png\n")

# Plot 2 — CL vs BF comparison
comparison_long <- comparison %>%
  tidyr::pivot_longer(
    cols      = c(CL_IBNR, BF_IBNR),
    names_to  = "method",
    values_to = "ibnr"
  ) %>%
  mutate(method = ifelse(method == "CL_IBNR",
                         "Chain-ladder", "Bornhuetter-Ferguson"))

p2 <- ggplot(comparison_long,
       aes(x = factor(AccidentYear), y = ibnr, fill = method)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("Chain-ladder"           = "#B5D4F4",
                               "Bornhuetter-Ferguson"   = "#0C447C")) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Chain-ladder vs Bornhuetter-Ferguson IBNR comparison",
    subtitle = "BF produces more stable estimates for immature accident years",
    x        = "Accident year",
    y        = "IBNR estimate ($000s)",
    fill     = "Method"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10),
    legend.position = "top"
  )

ggsave("outputs/charts/05_cl_vs_bf.png",
       p2, width = 10, height = 6, dpi = 150)
cat("Chart saved: 05_cl_vs_bf.png\n")

# ------------------------------------------------------------
# STEP 9 — SAVE RESULTS
# ------------------------------------------------------------
write_csv(bf_summary,  "data/processed/bf_results.csv")
write_csv(comparison,  "data/processed/cl_vs_bf_comparison.csv")

cat("\nResults saved to data/processed/\n")
cat("\nScript 03 complete.\n")
