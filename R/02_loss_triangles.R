# ============================================================
#  PHASE 3 — SCRIPT 2: LOSS DEVELOPMENT TRIANGLES
#  File    : r/02_loss_triangles.R
#  Purpose : Build paid loss development triangles,
#            calculate chain-ladder CDFs, project ultimates
#  Run in  : RStudio
# ============================================================

# ------------------------------------------------------------
# STEP 1 — LOAD LIBRARIES
# ------------------------------------------------------------
library(ChainLadder)
library(DBI)
library(RMySQL)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(readr)

# ------------------------------------------------------------
# STEP 2 — CONNECT AND PULL TRIANGLE DATA
# ------------------------------------------------------------
con <- dbConnect(
  RMySQL::MySQL(),
  host     = "localhost",
  port     = 3306,
  dbname   = "cas_pc_analysis",
  user     = "root",
  password = "Actuary123"           # update if needed
)

# Pull loss triangle from view
triangle_raw <- dbGetQuery(con, "
  SELECT *
  FROM v_loss_triangle
  ORDER BY AccidentYear
")

# Pull raw data for individual insurer triangles
raw_data <- dbGetQuery(con, "
  SELECT
    GRCODE, GRNAME, AccidentYear,
    DevelopmentLag, CumPaidLoss_B, IncurLoss_B,
    EarnedPremNet_B
  FROM ppauto
  WHERE Single = 1
  AND EarnedPremNet_B > 0
  ORDER BY GRCODE, AccidentYear, DevelopmentLag
")

dbDisconnect(con)
cat("Data pulled successfully\n")

# ------------------------------------------------------------
# STEP 3 — BUILD THE INDUSTRY PAID LOSS TRIANGLE
# Rows = accident years, columns = development lags
# This is the standard actuarial triangle format
# ------------------------------------------------------------

# Convert to matrix — ChainLadder expects a matrix
triangle_matrix <- triangle_raw %>%
  select(-AccidentYear) %>%
  as.matrix()

rownames(triangle_matrix) <- triangle_raw$AccidentYear

cat("\nIndustry paid loss triangle:\n")
print(triangle_matrix)

# Convert to ChainLadder triangle object
paid_triangle <- as.triangle(triangle_matrix)

cat("\nTriangle class confirmed:", class(paid_triangle), "\n")

# ------------------------------------------------------------
# STEP 4 — CALCULATE DEVELOPMENT LINK RATIOS
# Each ratio = paid at lag n+1 / paid at lag n
# Volume-weighted average across all accident years
# ------------------------------------------------------------

# Extract link ratios from triangle
link_ratios <- attr(ata(paid_triangle), "vwtd")

cat("\nVolume-weighted link ratios:\n")
for (i in seq_along(link_ratios)) {
  cat(sprintf("  Lag %d → %d: %.4f\n", i, i+1, link_ratios[i]))
}

# Calculate cumulative development factors (CDFs)
# CDF at lag n = product of all link ratios from lag n to ultimate
n_lags <- length(link_ratios)
cdfs <- numeric(n_lags)
cdfs[n_lags] <- link_ratios[n_lags]

for (i in (n_lags - 1):1) {
  cdfs[i] <- link_ratios[i] * cdfs[i + 1]
}

cat("\nCumulative development factors (CDF to ultimate):\n")
for (i in seq_along(cdfs)) {
  cat(sprintf("  Lag %d CDF: %.4f (multiply current paid by this to get ultimate)\n",
              i, cdfs[i]))
}

# ------------------------------------------------------------
# STEP 5 — CHAIN-LADDER ULTIMATE PROJECTION
# ------------------------------------------------------------

# Run chain-ladder method
cl_result <- MackChainLadder(paid_triangle, est.sigma = "Mack")

cat("\n--- CHAIN-LADDER RESULTS ---\n")
print(cl_result)

# Extract key outputs correctly
cl_df <- as.data.frame(summary(cl_result)$ByOrigin)

cat("\nChain-ladder summary:\n")
print(cl_df)

# Build clean summary table
cl_summary <- data.frame(
  AccidentYear = as.integer(rownames(paid_triangle)),
  PaidToDate   = round(as.numeric(cl_df$Latest), 0),
  UltimateEst  = round(as.numeric(cl_df$Ultimate), 0),
  IBNR         = round(as.numeric(cl_df$IBNR), 0),
  PctDeveloped = round(as.numeric(cl_df$Latest) /
                         as.numeric(cl_df$Ultimate) * 100, 1)
)

cat("\nClean summary:\n")
print(cl_summary)

cat(sprintf("\nTotal projected IBNR: %s\n",
            format(sum(cl_summary$IBNR), big.mark = ",")))
cat(sprintf("Total ultimate losses: %s\n",
            format(sum(cl_summary$UltimateEst), big.mark = ",")))

# ------------------------------------------------------------
# STEP 6 — MACK STANDARD ERROR
# Quantifies the uncertainty in our IBNR estimate
# This is what separates actuarial reserving from guesswork
# ------------------------------------------------------------

cat("\n--- RESERVE UNCERTAINTY (MACK METHOD) ---\n")
mack_summary <- summary(cl_result)
print(mack_summary)

# Extract standard errors
mack_se <- cl_result$Mack.S.E
total_ibnr <- sum(cl_summary$IBNR)
total_se   <- cl_result$Total.Mack.S.E

cat(sprintf("\nTotal IBNR estimate:  %s\n",
    format(round(total_ibnr, 0), big.mark = ",")))
cat(sprintf("Mack standard error:  %s\n",
    format(round(total_se, 0), big.mark = ",")))
cat(sprintf("Coefficient of variation: %.1f%%\n",
    total_se / total_ibnr * 100))

# 95% confidence interval for total IBNR
ci_lower <- total_ibnr - 1.96 * total_se
ci_upper <- total_ibnr + 1.96 * total_se
cat(sprintf("95%% confidence interval: [%s, %s]\n",
    format(round(ci_lower, 0), big.mark = ","),
    format(round(ci_upper, 0), big.mark = ",")))

# ------------------------------------------------------------
# STEP 7 — VISUALISE THE TRIANGLE
# ------------------------------------------------------------

# Plot 1 — development triangle heatmap
triangle_df <- triangle_raw %>%
  pivot_longer(
    cols      = starts_with("lag_"),
    names_to  = "lag",
    values_to = "paid_losses"
  ) %>%
  mutate(
    lag = as.integer(gsub("lag_", "", lag))
  ) %>%
  filter(!is.na(paid_losses))

p1 <- ggplot(triangle_df,
       aes(x = lag, y = factor(AccidentYear), fill = paid_losses)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = format(round(paid_losses / 1000, 0),
                               big.mark = ",")),
            size = 2.8, colour = "white") +
  scale_fill_gradient(low = "#B5D4F4", high = "#0C447C",
                      labels = comma) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title    = "Industry paid loss triangle — CAS Schedule P PP Auto",
    subtitle = "Cumulative paid losses ($000s) by accident year and development lag",
    x        = "Development lag (years)",
    y        = "Accident year",
    fill     = "Paid losses"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10),
    legend.position = "right"
  )

ggsave("outputs/charts/01_loss_triangle_heatmap.png",
       p1, width = 10, height = 6, dpi = 150)
cat("Chart saved: 01_loss_triangle_heatmap.png\n")

# Plot 2 — development curve by accident year
p2 <- ggplot(triangle_df,
       aes(x = lag, y = paid_losses,
           colour = factor(AccidentYear), group = AccidentYear)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_colour_viridis_d(name = "Accident year") +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title    = "Loss development curves by accident year",
    subtitle = "How cumulative paid losses grow over 10 development years",
    x        = "Development lag (years)",
    y        = "Cumulative paid losses ($000s)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10)
  )

ggsave("outputs/charts/02_development_curves.png",
       p2, width = 10, height = 6, dpi = 150)
cat("Chart saved: 02_development_curves.png\n")

# Plot 3 — chain-ladder ultimate vs paid
cl_plot_df <- cl_summary %>%
  pivot_longer(
    cols      = c(PaidToDate, UltimateEst),
    names_to  = "type",
    values_to = "amount"
  ) %>%
  mutate(type = ifelse(type == "PaidToDate",
                       "Paid to date", "Ultimate estimate"))

p3 <- ggplot(cl_plot_df,
       aes(x = factor(AccidentYear), y = amount, fill = type)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("Paid to date"      = "#B5D4F4",
                               "Ultimate estimate" = "#0C447C")) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Chain-ladder: paid to date vs projected ultimate",
    subtitle = "The gap between bars is the IBNR — claims not yet paid",
    x        = "Accident year",
    y        = "Losses ($000s)",
    fill     = ""
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10),
    legend.position = "top"
  )

ggsave("outputs/charts/03_chainladder_ultimate.png",
       p3, width = 10, height = 6, dpi = 150)
cat("Chart saved: 03_chainladder_ultimate.png\n")

# ------------------------------------------------------------
# STEP 8 — SAVE RESULTS
# ------------------------------------------------------------
write_csv(cl_summary, "data/processed/chainladder_results.csv")

link_ratio_df <- data.frame(
  from_lag        = 1:length(link_ratios),
  to_lag          = 2:(length(link_ratios) + 1),
  link_ratio      = round(link_ratios, 4),
  cdf_to_ultimate = round(cdfs, 4)
)

write_csv(link_ratio_df, "data/processed/link_ratios.csv")

cat("\nResults saved to data/processed/\n")
cat("\nScript 02 complete.\n")
