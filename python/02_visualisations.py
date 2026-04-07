# ============================================================
#  PHASE 4 — SCRIPT 2: VISUALISATIONS
#  File    : python/02_visualisations.py
#  Purpose : Publication-quality charts for the project
#            All charts saved to outputs/charts/
#  Run in  : VS Code
# ============================================================

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import numpy as np
import os

# ------------------------------------------------------------
# STEP 1 — SETUP
# ------------------------------------------------------------
PROJECT_DIR = r"C:\Users\User\Documents\pc-claims-affordability"
os.chdir(PROJECT_DIR)

# Chart style
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
dev_curve = pd.read_csv("data/processed/development_curve.csv")
rate_adeq = pd.read_csv("data/processed/rate_adequacy.csv")
link_rat  = pd.read_csv("data/processed/link_ratios.csv")

print("Data loaded. Generating charts...")

# ------------------------------------------------------------
# CHART 1 — LOSS RATIO TREND (1998–2007)
# The core story: underpricing, crisis, recovery
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

colors = [CORAL if lr > 64.5 else TEAL
          for lr in industry["paid_loss_ratio"]]

bars = ax.bar(industry["AccidentYear"],
              industry["paid_loss_ratio"],
              color=colors, width=0.7, zorder=3)

# Permissible loss ratio line
ax.axhline(y=64.5, color=CORAL, linewidth=1.5,
           linestyle="--", label="Permissible LR (64.5%)", zorder=4)

# Target line
ax.axhline(y=60, color=GRAY, linewidth=1,
           linestyle=":", label="Target LR (60%)", zorder=4)

# Value labels on bars
for bar, val in zip(bars, industry["paid_loss_ratio"]):
    ax.text(bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.5,
            f"{val:.1f}%", ha="center", va="bottom",
            fontsize=9, fontweight="bold",
            color=BLUE_DARK)

ax.set_xlabel("Accident year", fontsize=11)
ax.set_ylabel("Paid loss ratio (%)", fontsize=11)
ax.set_title("Industry paid loss ratio by accident year\n"
             "Red = above permissible threshold, requires rate increase",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xticks(industry["AccidentYear"])
ax.set_ylim(0, 95)
ax.legend(fontsize=10)

# Annotate crisis period
ax.annotate("Crisis period\n1999–2000",
            xy=(1999.5, 78), fontsize=9,
            color=CORAL, fontweight="bold",
            ha="center")

plt.tight_layout()
plt.savefig("outputs/charts/py01_loss_ratio_trend.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py01_loss_ratio_trend.png")

# ------------------------------------------------------------
# CHART 2 — FUNDING SURPLUS / DEFICIT BY YEAR
# Shows dollar amount of over/under funding
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

surplus = industry["funding_surplus_deficit"]
colors  = [TEAL if v >= 0 else CORAL for v in surplus]

bars = ax.bar(industry["AccidentYear"],
              surplus / 1000,
              color=colors, width=0.7, zorder=3)

ax.axhline(y=0, color="black", linewidth=1.2, zorder=4)

# Value labels
for bar, val in zip(bars, surplus / 1000):
    ypos = val + 1 if val >= 0 else val - 3
    ax.text(bar.get_x() + bar.get_width() / 2,
            ypos, f"${val:.0f}M",
            ha="center", va="bottom" if val >= 0 else "top",
            fontsize=8.5, fontweight="bold",
            color=BLUE_DARK)

ax.set_xlabel("Accident year", fontsize=11)
ax.set_ylabel("Funding surplus / deficit ($M)", fontsize=11)
ax.set_title("Industry funding surplus and deficit by accident year\n"
             "Green = premium exceeded claims + expenses, "
             "Red = shortfall",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xticks(industry["AccidentYear"])
ax.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"${x:.0f}M"))

plt.tight_layout()
plt.savefig("outputs/charts/py02_funding_surplus_deficit.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py02_funding_surplus_deficit.png")

# ------------------------------------------------------------
# CHART 3 — DEVELOPMENT CURVE
# The amortisation-style loss development pattern
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

ax.plot(dev_curve["DevelopmentLag"],
        dev_curve["pct_paid_of_incurred"],
        color=BLUE_DARK, linewidth=2.5,
        marker="o", markersize=8, zorder=3)

# Shade the unpaid area
ax.fill_between(dev_curve["DevelopmentLag"],
                dev_curve["pct_paid_of_incurred"],
                100, alpha=0.15, color=CORAL,
                label="Unpaid / IBNR")

ax.fill_between(dev_curve["DevelopmentLag"],
                0, dev_curve["pct_paid_of_incurred"],
                alpha=0.15, color=TEAL,
                label="Paid to date")

# Annotate key points
for _, row in dev_curve.iterrows():
    ax.annotate(f"{row['pct_paid_of_incurred']:.1f}%",
                xy=(row["DevelopmentLag"],
                    row["pct_paid_of_incurred"]),
                xytext=(0, 10),
                textcoords="offset points",
                ha="center", fontsize=8.5,
                color=BLUE_DARK)

ax.set_xlabel("Development lag (years)", fontsize=11)
ax.set_ylabel("% of ultimate losses paid", fontsize=11)
ax.set_title("Loss development curve — % of ultimate paid by lag\n"
             "Only 38% paid by end of year 1; 99.4% by year 10",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xticks(dev_curve["DevelopmentLag"])
ax.set_ylim(0, 115)
ax.legend(fontsize=10)

plt.tight_layout()
plt.savefig("outputs/charts/py03_development_curve.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py03_development_curve.png")

# ------------------------------------------------------------
# CHART 4 — SOLVENCY STATUS DONUT CHART
# Distribution of insurers by solvency status
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 7))

status_counts = scorecard["solvency_status"].value_counts()
status_order  = ["SEVERE DEFICIT", "DEFICIT",
                 "AT RISK", "WATCH", "SOLVENT"]
status_counts = status_counts.reindex(
    [s for s in status_order if s in status_counts.index])

colors_donut = [CORAL, "#E8593C", AMBER, BLUE_LIGHT, TEAL][:len(status_counts)]

wedges, texts, autotexts = ax.pie(
    status_counts.values,
    labels=status_counts.index,
    colors=colors_donut,
    autopct="%1.1f%%",
    pctdistance=0.82,
    wedgeprops=dict(width=0.5),
    startangle=90
)

for text in texts:
    text.set_fontsize(10)
for autotext in autotexts:
    autotext.set_fontsize(9)
    autotext.set_fontweight("bold")

ax.set_title("Insurer solvency status distribution\n"
             "Based on combined ratio including 28.5% expense load",
             fontsize=13, fontweight="bold", pad=15)

# Centre label
ax.text(0, 0, f"{len(scorecard)}\nInsurers",
        ha="center", va="center",
        fontsize=14, fontweight="bold", color=BLUE_DARK)

plt.tight_layout()
plt.savefig("outputs/charts/py04_solvency_donut.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py04_solvency_donut.png")

# ------------------------------------------------------------
# CHART 5 — COMBINED RATIO DISTRIBUTION
# Histogram showing spread of combined ratios
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

ax.hist(scorecard["combined_ratio"],
        bins=20, color=BLUE_MID,
        edgecolor="white", linewidth=0.8,
        zorder=3)

# Reference lines
ax.axvline(x=100, color=CORAL, linewidth=2,
           linestyle="--", label="Break-even (100%)")
ax.axvline(x=85, color=AMBER, linewidth=1.5,
           linestyle=":", label="Watch threshold (85%)")
ax.axvline(x=scorecard["combined_ratio"].mean(),
           color=BLUE_DARK, linewidth=2,
           linestyle="-",
           label=f"Mean ({scorecard['combined_ratio'].mean():.1f}%)")

ax.set_xlabel("Combined ratio (%)", fontsize=11)
ax.set_ylabel("Number of insurers", fontsize=11)
ax.set_title("Distribution of insurer combined ratios\n"
             "Insurers to the right of the red line are loss-making",
             fontsize=13, fontweight="bold", pad=15)
ax.legend(fontsize=10)

plt.tight_layout()
plt.savefig("outputs/charts/py05_combined_ratio_distribution.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py05_combined_ratio_distribution.png")

# ------------------------------------------------------------
# CHART 6 — LINK RATIOS BAR CHART
# Visual representation of chain-ladder development factors
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

x = [f"{int(r['from_lag'])}→{int(r['to_lag'])}"
     for _, r in link_rat.iterrows()]
y = link_rat["link_ratio"].values

bars = ax.bar(x, y, color=BLUE_MID,
              width=0.6, zorder=3)

ax.axhline(y=1.0, color=GRAY, linewidth=1.2,
           linestyle="--", label="No further development (1.000)")

# Value labels
for bar, val in zip(bars, y):
    ax.text(bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.005,
            f"{val:.4f}", ha="center", va="bottom",
            fontsize=8.5, color=BLUE_DARK)

ax.set_xlabel("Development lag transition", fontsize=11)
ax.set_ylabel("Link ratio", fontsize=11)
ax.set_title("Chain-ladder link ratios by development lag\n"
             "Lag 1→2 ratio of 1.83 means claims nearly double in year 2",
             fontsize=13, fontweight="bold", pad=15)
ax.legend(fontsize=10)
ax.set_ylim(0.98, 1.90)

plt.tight_layout()
plt.savefig("outputs/charts/py06_link_ratios.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py06_link_ratios.png")

# ------------------------------------------------------------
# CHART 7 — TOP 15 INSURERS BY COMBINED RATIO
# Horizontal bar chart
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 8))

top15 = scorecard.head(15).copy()
top15 = top15.sort_values("combined_ratio", ascending=True)

colors_bar = [CORAL if cr > 100 else
              AMBER if cr > 85 else TEAL
              for cr in top15["combined_ratio"]]

bars = ax.barh(top15["GRNAME"],
               top15["combined_ratio"],
               color=colors_bar, height=0.7, zorder=3)

ax.axvline(x=100, color=CORAL, linewidth=1.5,
           linestyle="--", label="Break-even (100%)")
ax.axvline(x=85, color=AMBER, linewidth=1,
           linestyle=":", label="Watch (85%)")

# Value labels
for bar, val in zip(bars, top15["combined_ratio"]):
    ax.text(val + 0.5, bar.get_y() + bar.get_height() / 2,
            f"{val:.1f}%", va="center", fontsize=9,
            color=BLUE_DARK)

ax.set_xlabel("Combined ratio (%)", fontsize=11)
ax.set_title("Top 15 insurers by combined ratio\n"
             "Red = loss-making, Amber = watch zone, Green = solvent",
             fontsize=13, fontweight="bold", pad=15)
ax.legend(fontsize=10)

plt.tight_layout()
plt.savefig("outputs/charts/py07_top15_combined_ratio.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py07_top15_combined_ratio.png")

# ------------------------------------------------------------
# CHART 8 — RATE ADEQUACY: INDICATED CHANGE BY YEAR
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 6))

colors_rate = [CORAL if v > 0 else TEAL
               for v in rate_adeq["indicated_change"]]

bars = ax.bar(rate_adeq["AccidentYear"],
              rate_adeq["indicated_change"] * 100,
              color=colors_rate, width=0.7, zorder=3)

ax.axhline(y=0, color="black", linewidth=1.2, zorder=4)

# Value labels
for bar, val in zip(bars, rate_adeq["indicated_change"] * 100):
    ypos = val + 0.3 if val >= 0 else val - 0.8
    ax.text(bar.get_x() + bar.get_width() / 2,
            ypos, f"{val:+.1f}%",
            ha="center",
            va="bottom" if val >= 0 else "top",
            fontsize=9, fontweight="bold",
            color=BLUE_DARK)

ax.set_xlabel("Accident year", fontsize=11)
ax.set_ylabel("Indicated rate change (%)", fontsize=11)
ax.set_title("Indicated rate change by accident year\n"
             "Red = rate increase needed, Green = over-adequate",
             fontsize=13, fontweight="bold", pad=15)
ax.set_xticks(rate_adeq["AccidentYear"])
ax.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"{x:+.0f}%"))

plt.tight_layout()
plt.savefig("outputs/charts/py08_indicated_rate_change.png",
            dpi=150, bbox_inches="tight")
plt.close()
print("Chart saved: py08_indicated_rate_change.png")

print("\nAll 8 charts saved to outputs/charts/")
print("Script 02 complete.")
