# ============================================================
#  PHASE 4 — SCRIPT 3: AFFORDABILITY DASHBOARD
#  File    : python/03_affordability_chart.py
#  Purpose : Multi-panel dashboard summarising the full
#            affordability analysis in one figure
#  Run in  : VS Code
# ============================================================

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import matplotlib.gridspec as gridspec
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
    "font.size"         : 10
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
dev_curve = pd.read_csv("data/processed/development_curve.csv")

print("Data loaded. Building dashboard...")

# ------------------------------------------------------------
# STEP 2 — BUILD DASHBOARD LAYOUT
# 2x3 grid of panels
# ------------------------------------------------------------
fig = plt.figure(figsize=(18, 12))
fig.suptitle(
    "P&C Claims Affordability Analysis — CAS Schedule P "
    "Private Passenger Auto (1998–2007)",
    fontsize=16, fontweight="bold", y=0.98
)

gs = gridspec.GridSpec(2, 3, figure=fig,
                       hspace=0.45, wspace=0.35)

# ------------------------------------------------------------
# PANEL 1 — Loss ratio vs permissible (top left)
# ------------------------------------------------------------
ax1 = fig.add_subplot(gs[0, 0])

colors = [CORAL if lr > 64.5 else TEAL
          for lr in industry["paid_loss_ratio"]]
ax1.bar(industry["AccidentYear"],
        industry["paid_loss_ratio"],
        color=colors, width=0.7, zorder=3)
ax1.axhline(y=64.5, color=CORAL, linewidth=1.5,
            linestyle="--", zorder=4)
ax1.set_title("Paid loss ratio vs permissible (64.5%)",
              fontsize=10, fontweight="bold")
ax1.set_xlabel("Accident year", fontsize=9)
ax1.set_ylabel("Loss ratio (%)", fontsize=9)
ax1.set_xticks(industry["AccidentYear"])
ax1.tick_params(axis="x", rotation=45, labelsize=8)
ax1.set_ylim(0, 95)

# ------------------------------------------------------------
# PANEL 2 — Funding surplus/deficit (top middle)
# ------------------------------------------------------------
ax2 = fig.add_subplot(gs[0, 1])

surplus = industry["funding_surplus_deficit"]
colors2 = [TEAL if v >= 0 else CORAL for v in surplus]
ax2.bar(industry["AccidentYear"],
        surplus / 1000,
        color=colors2, width=0.7, zorder=3)
ax2.axhline(y=0, color="black", linewidth=1, zorder=4)
ax2.set_title("Funding surplus / deficit ($M)",
              fontsize=10, fontweight="bold")
ax2.set_xlabel("Accident year", fontsize=9)
ax2.set_ylabel("$M", fontsize=9)
ax2.set_xticks(industry["AccidentYear"])
ax2.tick_params(axis="x", rotation=45, labelsize=8)
ax2.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"${x:.0f}M"))

# ------------------------------------------------------------
# PANEL 3 — Solvency status donut (top right)
# ------------------------------------------------------------
ax3 = fig.add_subplot(gs[0, 2])

status_order  = ["SEVERE DEFICIT", "DEFICIT",
                 "AT RISK", "WATCH", "SOLVENT"]
status_counts = scorecard["solvency_status"].value_counts()
status_counts = status_counts.reindex(
    [s for s in status_order if s in status_counts.index])

colors_donut = [CORAL, "#E8593C", AMBER,
                BLUE_LIGHT, TEAL][:len(status_counts)]

ax3.pie(status_counts.values,
        labels=[f"{s}\n({v})" for s, v
                in zip(status_counts.index,
                       status_counts.values)],
        colors=colors_donut,
        autopct="%1.0f%%",
        pctdistance=0.75,
        wedgeprops=dict(width=0.5),
        startangle=90,
        textprops={"fontsize": 8})

ax3.set_title("Insurer solvency status",
              fontsize=10, fontweight="bold")
ax3.text(0, 0, f"{len(scorecard)}\nInsurers",
         ha="center", va="center",
         fontsize=11, fontweight="bold",
         color=BLUE_DARK)

# ------------------------------------------------------------
# PANEL 4 — Development curve (bottom left)
# ------------------------------------------------------------
ax4 = fig.add_subplot(gs[1, 0])

ax4.plot(dev_curve["DevelopmentLag"],
         dev_curve["pct_paid_of_incurred"],
         color=BLUE_DARK, linewidth=2,
         marker="o", markersize=6, zorder=3)
ax4.fill_between(dev_curve["DevelopmentLag"],
                 dev_curve["pct_paid_of_incurred"],
                 100, alpha=0.15, color=CORAL)
ax4.fill_between(dev_curve["DevelopmentLag"],
                 0, dev_curve["pct_paid_of_incurred"],
                 alpha=0.15, color=TEAL)
ax4.set_title("Loss development curve",
              fontsize=10, fontweight="bold")
ax4.set_xlabel("Development lag (years)", fontsize=9)
ax4.set_ylabel("% of ultimate paid", fontsize=9)
ax4.set_xticks(dev_curve["DevelopmentLag"])
ax4.set_ylim(0, 110)

# ------------------------------------------------------------
# PANEL 5 — Indicated rate change (bottom middle)
# ------------------------------------------------------------
ax5 = fig.add_subplot(gs[1, 1])

colors5 = [CORAL if v > 0 else TEAL
           for v in rate_adeq["indicated_change"]]
ax5.bar(rate_adeq["AccidentYear"],
        rate_adeq["indicated_change"] * 100,
        color=colors5, width=0.7, zorder=3)
ax5.axhline(y=0, color="black", linewidth=1, zorder=4)
ax5.set_title("Indicated rate change by year",
              fontsize=10, fontweight="bold")
ax5.set_xlabel("Accident year", fontsize=9)
ax5.set_ylabel("Rate change (%)", fontsize=9)
ax5.set_xticks(rate_adeq["AccidentYear"])
ax5.tick_params(axis="x", rotation=45, labelsize=8)
ax5.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"{x:+.0f}%"))

# ------------------------------------------------------------
# PANEL 6 — Key metrics summary (bottom right)
# ------------------------------------------------------------
ax6 = fig.add_subplot(gs[1, 2])
ax6.axis("off")

metrics = [
    ("Total insurers analysed",       f"{len(scorecard)}"),
    ("Accident years covered",         "1998–2007"),
    ("Total earned premium",           "$8.7B"),
    ("Average paid loss ratio",
     f"{industry['paid_loss_ratio'].mean():.1f}%"),
    ("Years requiring rate increase",
     f"{(rate_adeq['indicated_change'] > 0).sum()} of 10"),
    ("Insurers in severe deficit",
     f"{(scorecard['solvency_status'] == 'SEVERE DEFICIT').sum()}"),
    ("Insurers fully solvent",
     f"{(scorecard['solvency_status'] == 'SOLVENT').sum()}"),
    ("Pass stress test (+15%)",
     f"{(scorecard['stress_test_result'] == 'Passes base and stress').sum()} of {len(scorecard)}"),
    ("Peak funding deficit",           "$66.3M (AY2000)"),
    ("Max indicated rate increase",    "+21.1% (AY2000)"),
]

y_pos = 0.95
for label, value in metrics:
    ax6.text(0.02, y_pos, label,
             transform=ax6.transAxes,
             fontsize=9, color=GRAY)
    ax6.text(0.98, y_pos, value,
             transform=ax6.transAxes,
             fontsize=9, fontweight="bold",
             color=BLUE_DARK, ha="right")
    ax6.plot([0.02, 0.98], [y_pos - 0.04, y_pos - 0.04],
             color=GRAY, linewidth=0.3,
             transform=ax6.transAxes)
    y_pos -= 0.095

ax6.set_title("Key findings summary",
              fontsize=10, fontweight="bold")

# ------------------------------------------------------------
# STEP 3 — SAVE DASHBOARD
# ------------------------------------------------------------
plt.savefig("outputs/charts/py09_affordability_dashboard.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Dashboard saved: py09_affordability_dashboard.png")
print("Script 03 complete.")
