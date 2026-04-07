# ============================================================
#  PHASE 4 — SCRIPT 4: STRESS TEST CHART
#  File    : python/04_stress_test_chart.py
#  Purpose : Visualise stress test results at industry and
#            insurer level — tornado chart + waterfall
#  Run in  : VS Code
# ============================================================

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np
import os

# ------------------------------------------------------------
# STEP 1 — SETUP
# ------------------------------------------------------------
PROJECT_DIR = r"C:\Users\User\Documents\pc-claims-affordability"
os.chdir(PROJECT_DIR)

plt.rcParams.update({
    "figure.facecolor"  : "white",
    "axes.facecolor"    : "white",
    "axes.spines.top"   : False,
    "axes.spines.right" : False,
    "axes.grid"         : True,
    "grid.alpha"        : 0.3,
    "grid.linestyle"    : "--",
    "font.family"       : "sans-serif",
    "font.size"         : 11
})

BLUE_DARK  = "#0C447C"
BLUE_MID   = "#378ADD"
BLUE_LIGHT = "#B5D4F4"
TEAL       = "#1D9E75"
CORAL      = "#D85A30"
AMBER      = "#BA7517"
GRAY       = "#888780"

# Load data
industry  = pd.read_csv("data/processed/industry_summary.csv")
scorecard = pd.read_csv("data/processed/insurer_scorecard.csv")
rate_adeq = pd.read_csv("data/processed/rate_adequacy.csv")
sensitivity = pd.read_csv("data/processed/sensitivity_analysis.csv")

print("Data loaded. Building stress test charts...")

# ------------------------------------------------------------
# CHART 1 — INDUSTRY STRESS TEST
# Base vs stressed surplus/deficit by year
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(12, 6))

x     = np.arange(len(industry))
width = 0.35

# Base surplus
base = industry["funding_surplus_deficit"] / 1000
# Stressed: apply 15% shock to paid claims
stressed = (industry["funding_surplus_deficit"] -
            industry["paid_claims"] * 0.15) / 1000

bars1 = ax.bar(x - width/2, base,
               width, label="Base case",
               color=BLUE_LIGHT, zorder=3)
bars2 = ax.bar(x + width/2, stressed,
               width, label="+15% severity stress",
               color=[CORAL if v < 0 else TEAL
                      for v in stressed],
               zorder=3)

ax.axhline(y=0, color="black", linewidth=1.2, zorder=4)

# Value labels on stressed bars
for bar, val in zip(bars2, stressed):
    ypos = val + 1 if val >= 0 else val - 3
    ax.text(bar.get_x() + bar.get_width() / 2,
            ypos, f"${val:.0f}M",
            ha="center",
            va="bottom" if val >= 0 else "top",
            fontsize=7.5, color=BLUE_DARK)

ax.set_xlabel("Accident year", fontsize=11)
ax.set_ylabel("Funding surplus / deficit ($M)", fontsize=11)
ax.set_title("Industry stress test — base vs +15% severity shock\n"
             "Only AY2004 passes the stress test",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xticks(x)
ax.set_xticklabels(industry["AccidentYear"])
ax.legend(fontsize=10)
ax.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"${x:.0f}M"))

plt.tight_layout()
plt.savefig("outputs/charts/py10_industry_stress_test.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py10_industry_stress_test.png")

# ------------------------------------------------------------
# CHART 2 — INSURER STRESS TEST RESULTS
# Stacked bar showing pass/fail distribution
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(10, 6))

stress_counts = scorecard["stress_test_result"].value_counts()
stress_order  = ["Fails base and stress",
                 "Passes base — fails stress",
                 "Passes base and stress"]
stress_counts = stress_counts.reindex(
    [s for s in stress_order if s in stress_counts.index])

colors_stress = [CORAL, AMBER, TEAL][:len(stress_counts)]

bars = ax.barh(stress_counts.index,
               stress_counts.values,
               color=colors_stress,
               height=0.5, zorder=3)

# Value labels
for bar, val in zip(bars, stress_counts.values):
    ax.text(val + 0.3,
            bar.get_y() + bar.get_height() / 2,
            f"{val} insurers ({val/len(scorecard)*100:.0f}%)",
            va="center", fontsize=10,
            color=BLUE_DARK, fontweight="bold")

ax.set_xlabel("Number of insurers", fontsize=11)
ax.set_title("Insurer stress test results — +15% severity shock\n"
             "Only 35 of 101 insurers pass both base and stress",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xlim(0, 55)
ax.grid(axis="y", alpha=0)

plt.tight_layout()
plt.savefig("outputs/charts/py11_insurer_stress_results.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py11_insurer_stress_results.png")

# ------------------------------------------------------------
# CHART 3 — SENSITIVITY TORNADO CHART
# Which assumptions drive the rate indication most?
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 7))

# Filter out base case and calculate change from base
base_ind = sensitivity.loc[
    sensitivity["Scenario"] == "Base case",
    "Indicated_Change"].values[0]

sens_plot = sensitivity[
    sensitivity["Scenario"] != "Base case"].copy()
sens_plot["change_from_base"] = (
    sens_plot["Indicated_Change"] - base_ind) * 100
sens_plot = sens_plot.sort_values(
    "change_from_base", key=abs, ascending=True)

colors_tornado = [CORAL if v > 0 else TEAL
                  for v in sens_plot["change_from_base"]]

bars = ax.barh(sens_plot["Scenario"],
               sens_plot["change_from_base"],
               color=colors_tornado,
               height=0.6, zorder=3)

ax.axvline(x=0, color="black", linewidth=1.2, zorder=4)

# Value labels
for bar, val in zip(bars, sens_plot["change_from_base"]):
    xpos = val + 0.05 if val >= 0 else val - 0.05
    ax.text(xpos,
            bar.get_y() + bar.get_height() / 2,
            f"{val:+.2f}pp",
            va="center",
            ha="left" if val >= 0 else "right",
            fontsize=9, color=BLUE_DARK)

ax.set_xlabel("Change in indicated rate vs base case (pp)",
              fontsize=11)
ax.set_title("Sensitivity analysis — tornado chart\n"
             f"Base case indication: "
             f"{base_ind*100:+.1f}% | "
             "Red = increases indication, Green = decreases",
             fontsize=13, fontweight="bold", pad=15)

plt.tight_layout()
plt.savefig("outputs/charts/py12_sensitivity_tornado.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py12_sensitivity_tornado.png")

# ------------------------------------------------------------
# CHART 4 — WATERFALL: PREMIUM TO SURPLUS
# How premium is consumed — claims, expenses, surplus
# Use the most recent adequate year (2007)
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

ay2007 = industry[industry["AccidentYear"] == 2007].iloc[0]
premium  = ay2007["earned_premium"] / 1000
claims   = ay2007["paid_claims"] / 1000
expenses = premium * 0.285
surplus  = premium - claims - expenses

categories = ["Earned\npremium", "Paid\nclaims",
              "Operating\nexpenses", "Underwriting\nsurplus"]
values     = [premium, -claims, -expenses, surplus]
colors_wf  = [BLUE_MID, CORAL, AMBER, TEAL]

# Running total for waterfall
running = [0, premium, premium - claims,
           premium - claims - expenses]

bars = ax.bar(categories, [abs(v) for v in values],
              bottom=[0, 0, premium - claims, 0],
              color=colors_wf, width=0.5, zorder=3)

# Override surplus bar position
bars[3].set_y(0)
bars[3].set_height(surplus)

# Value labels
for bar, val, cat in zip(bars, values, categories):
    ypos = bar.get_y() + bar.get_height() + 0.5
    ax.text(bar.get_x() + bar.get_width() / 2,
            ypos, f"${abs(val):.0f}M",
            ha="center", va="bottom",
            fontsize=10, fontweight="bold",
            color=BLUE_DARK)

ax.set_ylabel("$M", fontsize=11)
ax.set_title("Premium waterfall — AY2007\n"
             "How $1,016M of earned premium is consumed",
             fontsize=13, fontweight="bold", pad=15)
ax.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"${x:.0f}M"))

plt.tight_layout()
plt.savefig("outputs/charts/py13_premium_waterfall.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py13_premium_waterfall.png")

print("\nAll 4 stress test charts saved to outputs/charts/")
print("Script 04 complete.")
print("\nPhase 4 — Python visualisations complete.")
