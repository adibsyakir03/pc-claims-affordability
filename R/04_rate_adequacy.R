# ============================================================
#  PHASE 3 — SCRIPT 4: RATE ADEQUACY
#  File    : r/04_rate_adequacy.R
#  Purpose : Calculate indicated rate change using loss ratio
#            method, test rate adequacy per accident year,
#            run sensitivity analysis on key assumptions
#  Run in  : RStudio
# ============================================================

# ------------------------------------------------------------
# STEP 1 — LOAD LIBRARIES
# ------------------------------------------------------------
library(DBI)
library(RMySQL)
library(dplyr)
library(tidyr)
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

industry <- dbGetQuery(con, "
  SELECT * FROM v_industry_summary
  ORDER BY AccidentYear
")

scorecard <- dbGetQuery(con, "
  SELECT * FROM v_insurer_scorecard
  ORDER BY combined_ratio DESC
")

dbDisconnect(con)
cat("Data pulled successfully\n")

# ------------------------------------------------------------
# STEP 3 — RATE ADEQUACY FRAMEWORK
# The indicated rate change formula:
#
#   Indicated Change = [(Proj LR + FER) / (1 - VER - PM - Inv)] - 1
#
# Where:
#   Proj LR = Projected ultimate loss ratio
#   FER     = Fixed expense ratio (16.0%)
#   VER     = Variable expense ratio (12.5%)
#   PM      = Target profit margin (5.0%)
#   Inv     = Investment income offset (2.0%)
#
# These are standard US private passenger auto assumptions
# consistent with CAS Exam 5 ratemaking methodology
# ------------------------------------------------------------

# Define assumptions
FER <- 0.160    # Fixed expense ratio
VER <- 0.125    # Variable expense ratio
PM  <- 0.050    # Target profit margin
INV <- 0.020    # Investment income offset

# Permissible loss ratio — maximum LR that keeps combined ratio
# at or below 100% after expenses and profit margin
permissible_lr <- 1 - FER - VER - PM - INV
cat(sprintf("Permissible loss ratio: %.1f%%\n",
    permissible_lr * 100))

# ------------------------------------------------------------
# STEP 4 — CALCULATE INDICATED RATE CHANGE PER ACCIDENT YEAR
# ------------------------------------------------------------

rate_adequacy <- industry %>%
  mutate(
    # Projected LR — use incurred loss ratio as best estimate
    proj_lr = incurred_loss_ratio / 100,

    # Indicated rate change formula
    indicated_change = (proj_lr + FER) /
                       (1 - VER - PM - INV) - 1,

    # Rate adequacy gap in percentage points
    adequacy_gap = paid_loss_ratio / 100 - permissible_lr,

    # Dollar value of rate gap
    rate_gap_dollars = round(earned_premium *
                             indicated_change, 0),

    # Classification
    rate_status = case_when(
      indicated_change >  0.10 ~ "Significant increase needed",
      indicated_change >  0.00 ~ "Moderate increase needed",
      indicated_change > -0.05 ~ "Broadly adequate",
      TRUE                     ~ "Over-adequate — reduction possible"
    )
  )

cat("\n--- RATE ADEQUACY BY ACCIDENT YEAR ---\n")
print(rate_adequacy %>%
        select(AccidentYear, paid_loss_ratio,
               incurred_loss_ratio, indicated_change,
               rate_gap_dollars, rate_status))

# ------------------------------------------------------------
# STEP 5 — SENSITIVITY ANALYSIS
# How does the indicated rate change respond to
# different assumptions?
# ------------------------------------------------------------

cat("\n--- SENSITIVITY ANALYSIS ---\n")
cat("Base indicated rate change by accident year\n")
cat("vs changes in key assumptions\n\n")

# Use overall average loss ratio as single point estimate
avg_lr <- mean(industry$incurred_loss_ratio) / 100

# Base case
base_indication <- (avg_lr + FER) / (1 - VER - PM - INV) - 1

# Sensitivity scenarios
scenarios <- data.frame(
  Scenario = c(
    "Base case",
    "Loss ratio +5pp",
    "Loss ratio -5pp",
    "Expenses +3pp",
    "Expenses -3pp",
    "Target margin +2pp",
    "Target margin -2pp",
    "Severity trend +2%",
    "Severity trend -2%"
  ),
  Proj_LR = c(
    avg_lr,
    avg_lr + 0.05,
    avg_lr - 0.05,
    avg_lr,
    avg_lr,
    avg_lr,
    avg_lr,
    avg_lr * 1.02,
    avg_lr * 0.98
  ),
  FER_used = c(
    FER, FER, FER,
    FER + 0.03, FER - 0.03,
    FER, FER, FER, FER
  ),
  PM_used = c(
    PM, PM, PM, PM, PM,
    PM + 0.02, PM - 0.02,
    PM, PM
  )
) %>%
  mutate(
    Indicated_Change = round(
      (Proj_LR + FER_used) /
      (1 - VER - PM_used - INV) - 1, 4
    ),
    Indicated_Pct = paste0(round(Indicated_Change * 100, 1), "%")
  )

print(scenarios %>% select(Scenario, Indicated_Pct))

# ------------------------------------------------------------
# STEP 6 — IDENTIFY YEARS REQUIRING RATE ACTION
# ------------------------------------------------------------

cat("\n--- YEARS REQUIRING RATE ACTION ---\n")

action_years <- rate_adequacy %>%
  filter(indicated_change > 0) %>%
  arrange(desc(indicated_change))

for (i in 1:nrow(action_years)) {
  cat(sprintf(
    "AY%d: +%.1f%% indicated — %s — gap of $%s\n",
    action_years$AccidentYear[i],
    action_years$indicated_change[i] * 100,
    action_years$rate_status[i],
    format(abs(action_years$rate_gap_dollars[i]),
           big.mark = ",")
  ))
}

# ------------------------------------------------------------
# STEP 7 — INSURER LEVEL RATE ADEQUACY
# Which insurers need the biggest rate increases?
# ------------------------------------------------------------

insurer_rates <- scorecard %>%
  mutate(
    proj_lr          = incurred_loss_ratio / 100,
    indicated_change = (proj_lr + FER) /
                       (1 - VER - PM - INV) - 1,
    rate_status = case_when(
      indicated_change >  0.20 ~ "Urgent — >20% needed",
      indicated_change >  0.10 ~ "Significant — 10-20% needed",
      indicated_change >  0.00 ~ "Moderate — 0-10% needed",
      indicated_change > -0.05 ~ "Broadly adequate",
      TRUE                     ~ "Over-adequate"
    )
  ) %>%
  arrange(desc(indicated_change))

cat("\n--- TOP 10 INSURERS NEEDING RATE INCREASES ---\n")
print(insurer_rates %>%
        select(GRNAME, incurred_loss_ratio,
               indicated_change, rate_status) %>%
        head(10))

cat("\n--- TOP 10 MOST OVER-ADEQUATE INSURERS ---\n")
print(insurer_rates %>%
        select(GRNAME, incurred_loss_ratio,
               indicated_change, rate_status) %>%
        tail(10))

# Rate status summary
cat("\n--- RATE STATUS SUMMARY ---\n")
print(table(insurer_rates$rate_status))

# ------------------------------------------------------------
# STEP 8 — VISUALISATIONS
# ------------------------------------------------------------

# Plot 1 — indicated rate change by accident year
p1 <- ggplot(rate_adequacy,
       aes(x = factor(AccidentYear),
           y = indicated_change * 100,
           fill = indicated_change > 0)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.8,
             colour = "grey30") +
  scale_fill_manual(values = c("TRUE"  = "#D85A30",
                               "FALSE" = "#1D9E75"),
                    labels = c("TRUE"  = "Rate increase needed",
                               "FALSE" = "Rate decrease possible"),
                    name   = "") +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Indicated rate change by accident year",
    subtitle = paste0("Based on loss ratio method — permissible LR = ",
                      round(permissible_lr * 100, 1), "%"),
    x        = "Accident year",
    y        = "Indicated rate change (%)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 13),
    plot.subtitle   = element_text(colour = "grey50", size = 10),
    legend.position = "top"
  )

ggsave("outputs/charts/06_indicated_rate_change.png",
       p1, width = 10, height = 6, dpi = 150)
cat("Chart saved: 06_indicated_rate_change.png\n")

# Plot 2 — loss ratio vs permissible loss ratio
p2 <- ggplot(rate_adequacy,
       aes(x = factor(AccidentYear))) +
  geom_col(aes(y = paid_loss_ratio),
           fill = "#B5D4F4", width = 0.7) +
  geom_hline(yintercept = permissible_lr * 100,
             colour = "#D85A30", linewidth = 1.2,
             linetype = "dashed") +
  annotate("text", x = 1.5,
           y = permissible_lr * 100 + 1.5,
           label = paste0("Permissible LR: ",
                          round(permissible_lr * 100, 1), "%"),
           colour = "#D85A30", size = 3.5) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Paid loss ratio vs permissible loss ratio",
    subtitle = "Years above the red line required a rate increase",
    x        = "Accident year",
    y        = "Paid loss ratio (%)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10)
  )

ggsave("outputs/charts/07_lr_vs_permissible.png",
       p2, width = 10, height = 6, dpi = 150)
cat("Chart saved: 07_lr_vs_permissible.png\n")

# Plot 3 — sensitivity tornado chart
scenarios_plot <- scenarios %>%
  filter(Scenario != "Base case") %>%
  mutate(
    Change_from_base = Indicated_Change - base_indication,
    Direction = ifelse(Change_from_base > 0,
                       "Increases indication", "Decreases indication")
  ) %>%
  arrange(abs(Change_from_base))

p3 <- ggplot(scenarios_plot,
       aes(x = reorder(Scenario, abs(Change_from_base)),
           y = Change_from_base * 100,
           fill = Direction)) +
  geom_col(width = 0.7) +
  coord_flip() +
  scale_fill_manual(values = c(
    "Increases indication" = "#D85A30",
    "Decreases indication" = "#1D9E75")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Sensitivity analysis — rate indication tornado chart",
    subtitle = "Impact of changing each assumption vs base case",
    x        = "",
    y        = "Change in indicated rate vs base case",
    fill     = ""
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(colour = "grey50", size = 10),
    legend.position = "top"
  )

ggsave("outputs/charts/08_sensitivity_tornado.png",
       p3, width = 10, height = 6, dpi = 150)
cat("Chart saved: 08_sensitivity_tornado.png\n")

# ------------------------------------------------------------
# STEP 9 — SAVE RESULTS
# ------------------------------------------------------------
write_csv(rate_adequacy,  "data/processed/rate_adequacy.csv")
write_csv(insurer_rates,  "data/processed/insurer_rate_adequacy.csv")
write_csv(scenarios,      "data/processed/sensitivity_analysis.csv")

cat("\nResults saved to data/processed/\n")
cat("\nScript 04 complete.\n")
cat("\nPhase 3 — R analysis complete.\n")
