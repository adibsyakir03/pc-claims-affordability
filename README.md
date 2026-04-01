# P&C Claims Affordability Analysis
### Can a motor insurer pay its claims from current premium intake?

![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![Data](https://img.shields.io/badge/data-CAS%20Schedule%20P%20(NAIC)-blue)
![Tools](https://img.shields.io/badge/tools-MySQL%20%7C%20R%20%7C%20Python-green)

---

## Business question

Given real premium intake and claims data from U.S. private passenger auto insurers,
can each insurer fund its current and projected future claims obligations?
This project applies actuarial pricing and reserving methodology to answer that question
using publicly available regulatory filings.

---

## Dataset

**Source:** Casualty Actuarial Society (CAS) — Loss Reserving Data Pulled from NAIC Schedule P  
**Line:** Private Passenger Auto Liability / Medical  
**Coverage:** Accident years 1998–2007, 10 development lags, 157 U.S. insurers  
**Download:** https://www.casact.org/publications-research/research/research-resources/loss-reserving-data-pulled-naic-schedule-p

> Raw data is not committed to this repository. Download the CSV from the link above
> and place it in `data/raw/` before running any scripts.

**Key fields used:**

| Field | Description |
|---|---|
| `GRCODE` | NAIC company code |
| `GRNAME` | Company name |
| `AccidentYear` | Year losses were incurred |
| `DevelopmentLag` | Months since accident year (12, 24 … 120) |
| `CumPaidLoss_B` | Cumulative paid losses (net of reinsurance) |
| `IncurLoss_B` | Incurred losses including case reserves |
| `BulkLoss_B` | Bulk & IBNR reserves |
| `EarnedPremNet_B` | Net earned premium |

---

## Methodology

This project follows standard P&C actuarial pricing and reserving workflow:

1. **Data ingestion** — Load CAS CSV into MySQL, validate, document
2. **Exploratory analysis** — Loss ratio trends, insurer profiles, data quality
3. **Claims affordability** — Premium intake vs. paid claims + operating expenses
4. **Loss development** — Chain-ladder triangles, CDFs, ultimate loss projection
5. **IBNR estimation** — Bornhuetter-Ferguson method for unreported claims
6. **Rate adequacy** — Indicated rate change, permissible loss ratio
7. **Stress testing** — +15% severity shock scenario
8. **Findings** — Reserve adequacy verdict per insurer, rate recommendations

---

## Tools & stack

| Layer | Tool | Purpose |
|---|---|---|
| Database | MySQL 8.0 | Data storage, cleaning, SQL analysis |
| Actuarial analysis | R (`ChainLadder`, `actuar`) | Loss triangles, IBNR, reserving |
| Visualisation | Python (`pandas`, `matplotlib`, `seaborn`) | Charts, dashboard, notebook |
| Version control | Git / GitHub | Reproducibility |

---

## Repository structure

```
pc-claims-affordability/
│
├── data/
│   ├── raw/                  # CAS CSV goes here (not committed)
│   └── processed/            # Cleaned exports from R/Python
│
├── sql/
│   ├── 01_load_data.sql      # Schema creation + LOAD DATA INFILE
│   ├── 02_eda_queries.sql    # Exploratory queries
│   ├── 03_affordability.sql  # Core affordability analysis
│   └── 04_views.sql          # Executive summary view
│
├── r/
│   ├── 01_data_pull.R        # Connect to MySQL, pull data
│   ├── 02_loss_triangles.R   # Chain-ladder development
│   ├── 03_ibnr_bf.R          # Bornhuetter-Ferguson IBNR
│   └── 04_rate_adequacy.R    # Rate indication + stress test
│
├── python/
│   ├── 01_load_and_explore.py
│   ├── 02_visualisations.py
│   ├── 03_affordability_chart.py
│   └── 04_stress_test_chart.py
│
├── notebooks/
│   └── analysis_walkthrough.ipynb
│
├── docs/
│   ├── data_dictionary.md    # Field definitions + actuarial notes
│   └── findings.md           # Key results + recommendations
│
├── outputs/
│   └── charts/               # Saved PNG/SVG outputs
│
├── .gitignore
├── requirements.txt          # Python dependencies
├── packages.R                # R package list
└── README.md
```

---

## Key findings

> *(To be completed after analysis — Section 5 of the project)*

---

## How to reproduce

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/pc-claims-affordability.git
cd pc-claims-affordability
```

### 2. Download the data
Download `ppauto_pos98-07.csv` from the CAS link above and save it to:
```
data/raw/ppauto_pos.csv
```

### 3. Set up MySQL
```bash
mysql -u root -p < sql/01_load_data.sql
```

### 4. Run R analysis
```r
# Install packages first
source("packages.R")

# Then run in order
source("r/01_data_pull.R")
source("r/02_loss_triangles.R")
source("r/03_ibnr_bf.R")
source("r/04_rate_adequacy.R")
```

### 5. Run Python visualisations
```bash
pip install -r requirements.txt
python python/02_visualisations.py
python python/03_affordability_chart.py
python python/04_stress_test_chart.py
```

---

## Actuarial context

This project applies methods taught in **CAS Exam 5** (Basic Ratemaking and
Estimation of Claim Liabilities). The affordability question — whether premium
intake can fund obligations — sits at the intersection of pricing adequacy
and loss reserving, two of the core disciplines of a P&C actuarial analyst.

The CAS Schedule P dataset is used in published actuarial research and is
the standard benchmark dataset for loss reserving studies.

---

## Author

**Adib Syakir**  
Aspiring Actuarial Analyst  
www.linkedin.com/in/
adib-syakir-b05605336
 | adibsyakir03@gmail.com

---

*Data source: Casualty Actuarial Society. CAS is not affiliated with this project.*
