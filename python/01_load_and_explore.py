# ============================================================
#  PHASE 4 — SCRIPT 1: LOAD AND EXPLORE
#  File    : python/01_load_and_explore.py
#  Purpose : Load CSV files from data/processed/,
#            validate data, produce summary statistics
#  Run in  : Command Prompt or VS Code
# ============================================================

import pandas as pd
import numpy as np
import os

# ------------------------------------------------------------
# STEP 1 — SET WORKING DIRECTORY
# ------------------------------------------------------------
# Change this path to match your project folder
PROJECT_DIR = r"C:\Users\User\Documents\pc-claims-affordability"
os.chdir(PROJECT_DIR)
print(f"Working directory: {os.getcwd()}")

# ------------------------------------------------------------
# STEP 2 — LOAD ALL PROCESSED FILES
# ------------------------------------------------------------
print("\nLoading processed data files...")

industry    = pd.read_csv("data/processed/industry_summary.csv")
scorecard   = pd.read_csv("data/processed/insurer_scorecard.csv")
dev_curve   = pd.read_csv("data/processed/development_curve.csv")
triangle    = pd.read_csv("data/processed/loss_triangle.csv")
rate_adeq   = pd.read_csv("data/processed/rate_adequacy.csv")
bf_results  = pd.read_csv("data/processed/bf_results.csv")
link_ratios = pd.read_csv("data/processed/link_ratios.csv")

print("All files loaded successfully")

# ------------------------------------------------------------
# STEP 3 — VALIDATE EACH DATASET
# ------------------------------------------------------------
datasets = {
    "industry_summary"  : industry,
    "insurer_scorecard" : scorecard,
    "development_curve" : dev_curve,
    "loss_triangle"     : triangle,
    "rate_adequacy"     : rate_adeq,
    "bf_results"        : bf_results,
    "link_ratios"       : link_ratios
}

print("\n--- DATASET SUMMARY ---")
for name, df in datasets.items():
    print(f"{name:25s} {df.shape[0]:4d} rows x {df.shape[1]:2d} cols")

# ------------------------------------------------------------
# STEP 4 — INDUSTRY SUMMARY OVERVIEW
# ------------------------------------------------------------
print("\n--- INDUSTRY SUMMARY ---")
print(industry[["AccidentYear", "earned_premium",
                "paid_loss_ratio", "combined_ratio",
                "funding_surplus_deficit",
                "affordability_status"]].to_string(index=False))

# Key statistics
print(f"\nAverage paid loss ratio: "
      f"{industry['paid_loss_ratio'].mean():.1f}%")
print(f"Best year:  AY{industry.loc[industry['paid_loss_ratio'].idxmin(), 'AccidentYear']}"
      f" at {industry['paid_loss_ratio'].min():.1f}%")
print(f"Worst year: AY{industry.loc[industry['paid_loss_ratio'].idxmax(), 'AccidentYear']}"
      f" at {industry['paid_loss_ratio'].max():.1f}%")
print(f"Years underfunded: "
      f"{(industry['affordability_status'] == 'UNDERFUNDED').sum()}")

# ------------------------------------------------------------
# STEP 5 — INSURER SCORECARD OVERVIEW
# ------------------------------------------------------------
print("\n--- INSURER SCORECARD SUMMARY ---")
print(f"Total insurers: {len(scorecard)}")
print(f"\nSolvency status breakdown:")
print(scorecard["solvency_status"].value_counts().to_string())
print(f"\nStress test breakdown:")
print(scorecard["stress_test_result"].value_counts().to_string())

# Top 5 worst combined ratios
print(f"\nTop 5 worst combined ratios:")
print(scorecard[["GRNAME", "combined_ratio", "solvency_status"]]
      .head(5).to_string(index=False))

# Top 5 best combined ratios
print(f"\nTop 5 best combined ratios:")
print(scorecard[["GRNAME", "combined_ratio", "solvency_status"]]
      .tail(5).to_string(index=False))

# ------------------------------------------------------------
# STEP 6 — DEVELOPMENT CURVE OVERVIEW
# ------------------------------------------------------------
print("\n--- DEVELOPMENT CURVE ---")
print(dev_curve[["DevelopmentLag", "avg_cum_paid",
                 "pct_paid_of_incurred"]].to_string(index=False))

# ------------------------------------------------------------
# STEP 7 — LINK RATIOS OVERVIEW
# ------------------------------------------------------------
print("\n--- LINK RATIOS ---")
print(link_ratios.to_string(index=False))

# Cumulative factor from lag 1
cdf_lag1 = link_ratios["cdf_to_ultimate"].iloc[0]
print(f"\nCDF from lag 1 to ultimate: {cdf_lag1:.4f}")
print(f"Meaning: multiply lag 1 paid losses by {cdf_lag1:.2f}"
      f" to get projected ultimate")

# ------------------------------------------------------------
# STEP 8 — RATE ADEQUACY OVERVIEW
# ------------------------------------------------------------
print("\n--- RATE ADEQUACY ---")
print(rate_adeq[["AccidentYear", "paid_loss_ratio",
                 "indicated_change", "rate_status"]]
      .to_string(index=False))

years_needing_increase = (rate_adeq["indicated_change"] > 0).sum()
print(f"\nYears needing rate increase: {years_needing_increase} of "
      f"{len(rate_adeq)}")

print("\nScript 01 complete — data validated and ready for visualisation")
