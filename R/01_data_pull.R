# ============================================================
#  PHASE 3 — SCRIPT 1: DATA PULL
#  File    : r/01_data_pull.R
#  Purpose : Connect R to MySQL, pull data from views,
#            validate and save to data/processed/
#  Run in  : RStudio
# ============================================================

# ------------------------------------------------------------
# STEP 1 — LOAD LIBRARIES
# ------------------------------------------------------------
library(DBI)
library(RMySQL)
library(dplyr)
library(readr)

# ------------------------------------------------------------
# STEP 2 — CONNECT TO MYSQL
# Update password to match your MySQL root password
# ------------------------------------------------------------
con <- dbConnect(
  RMySQL::MySQL(),
  host     = "localhost",
  port     = 3306,
  dbname   = "cas_pc_analysis",
  user     = "root",
  password = "Actuary123"   
)

# Confirm connection
cat("Connected to MySQL successfully\n")
cat("Available tables and views:\n")
print(dbListTables(con))

# ------------------------------------------------------------
# STEP 3 — PULL DATA FROM VIEWS
# ------------------------------------------------------------

# Industry summary — one row per accident year
industry_summary <- dbGetQuery(con, "
  SELECT *
  FROM v_industry_summary
  ORDER BY AccidentYear
")

cat("\nIndustry summary — rows:", nrow(industry_summary), "\n")
print(industry_summary)

# Insurer scorecard — one row per insurer
insurer_scorecard <- dbGetQuery(con, "
  SELECT *
  FROM v_insurer_scorecard
  ORDER BY combined_ratio DESC
")

cat("\nInsurer scorecard — rows:", nrow(insurer_scorecard), "\n")
print(head(insurer_scorecard, 10))

# Development curve — lag 1 to 10
development_curve <- dbGetQuery(con, "
  SELECT *
  FROM v_development_curve
  ORDER BY DevelopmentLag
")

cat("\nDevelopment curve — rows:", nrow(development_curve), "\n")
print(development_curve)

# Loss triangle — wide format for ChainLadder
loss_triangle <- dbGetQuery(con, "
  SELECT *
  FROM v_loss_triangle
  ORDER BY AccidentYear
")

cat("\nLoss triangle — rows:", nrow(loss_triangle), "\n")
print(loss_triangle)

# Raw data — all lags, for detailed analysis
raw_data <- dbGetQuery(con, "
  SELECT
    GRCODE,
    GRNAME,
    AccidentYear,
    DevelopmentLag,
    EarnedPremNet_B,
    CumPaidLoss_B,
    IncurLoss_B,
    BulkLoss_B
  FROM ppauto
  WHERE Single = 1
  AND EarnedPremNet_B > 0
  ORDER BY GRCODE, AccidentYear, DevelopmentLag
")

cat("\nRaw data — rows:", nrow(raw_data), "\n")

# ------------------------------------------------------------
# STEP 4 — VALIDATE THE DATA
# ------------------------------------------------------------
cat("\n--- VALIDATION CHECKS ---\n")

# Check accident years
cat("Accident years:", paste(sort(unique(industry_summary$AccidentYear)),
    collapse = ", "), "\n")

# Check insurer count
cat("Total insurers:", nrow(insurer_scorecard), "\n")

# Check loss triangle shape
cat("Triangle dimensions:", nrow(loss_triangle), "rows x",
    ncol(loss_triangle), "columns\n")

# Check for any NA values in key columns
cat("NA values in industry summary:",
    sum(is.na(industry_summary)), "\n")
cat("NA values in loss triangle:",
    sum(is.na(loss_triangle)), "\n")

# Solvency status breakdown
cat("\nSolvency status breakdown:\n")
print(table(insurer_scorecard$solvency_status))

# Stress test breakdown
cat("\nStress test breakdown:\n")
print(table(insurer_scorecard$stress_test_result))

# ------------------------------------------------------------
# STEP 5 — SAVE TO data/processed/
# These CSV files are used by Python in Phase 4
# ------------------------------------------------------------
write_csv(industry_summary,  "data/processed/industry_summary.csv")
write_csv(insurer_scorecard, "data/processed/insurer_scorecard.csv")
write_csv(development_curve, "data/processed/development_curve.csv")
write_csv(loss_triangle,     "data/processed/loss_triangle.csv")
write_csv(raw_data,          "data/processed/raw_data.csv")

cat("\nAll files saved to data/processed/\n")

# ------------------------------------------------------------
# STEP 6 — DISCONNECT
# Always close the connection when done
# ------------------------------------------------------------
dbDisconnect(con)
cat("MySQL connection closed.\n")
