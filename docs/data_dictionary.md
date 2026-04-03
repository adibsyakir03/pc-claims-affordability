# Data dictionary — CAS Schedule P (PP Auto)

**Source:** Casualty Actuarial Society / NAIC Schedule P  
**File:** `ppauto_pos.csv`  
**Last updated:** December 2025 (CAS)  
**Rows:** ~15,700 (157 insurers × 10 accident years × 10 development lags)

---

## Table structure

Each row represents **one insurer × one accident year × one development lag**.
This is a loss development triangle in "long" format — the standard input
format for chain-ladder and Bornhuetter-Ferguson reserving methods.

---

## Field definitions

| Field | Type | Description | Actuarial notes |
|---|---|---|---|
| `GRCODE` | INT | NAIC company code | Primary key for insurer identity. Group codes aggregate subsidiaries. |
| `GRNAME` | VARCHAR | NAIC company name | Human-readable insurer name. Use for labelling only; join on GRCODE. |
| `AccidentYear` | INT | Year losses were incurred | Range: 1998–2007. This is the *accident* year, not the policy or report year. |
| `DevelopmentYear` | INT | Calendar year of the data point | = AccidentYear + DevelopmentLag - 1 |
| `DevelopmentLag` | INT | Months of development (12–120) | 12 = end of first year; 120 = fully developed (10 years). Used to build triangle columns. |
| `IncurLoss_B` | DECIMAL | Incurred losses + allocated expenses at year end | = Paid losses + case reserves. Includes ALAE (allocated loss adjustment expenses). Net of reinsurance. |
| `CumPaidLoss_B` | DECIMAL | Cumulative paid losses + ALAE at year end | Cash actually paid out the door, cumulative. Key input to the affordability analysis. |
| `BulkLoss_B` | DECIMAL | Bulk & IBNR reserves on net losses | Insurer's own IBNR estimate. Compare to our BF estimate as a validation check. |
| `PostedReserve2007` | DECIMAL | Posted reserves as of year-end 2007 | From Underwriting & Investment Exhibit. Used for the "lower triangle" validation. |
| `EarnedPremDIR_B` | DECIMAL | Earned premium — direct & assumed | Gross of ceded reinsurance. |
| `EarnedPremCeded_B` | DECIMAL | Earned premium — ceded | Amount ceded to reinsurers. |
| `EarnedPremNet_B` | DECIMAL | Earned premium — net of reinsurance | = EarnedPremDIR_B − EarnedPremCeded_B. **Primary premium field used in this analysis.** |
| `Single` | TINYINT | 1 = single entity, 0 = group insurer | Groups have internal reinsurance arrangements. Filter to Single=1 for cleaner individual analysis, or analyse both and note the difference. |

---

## Key derived fields (calculated in SQL / R)

| Derived field | Formula | Meaning |
|---|---|---|
| `paid_loss_ratio` | CumPaidLoss_B / EarnedPremNet_B | % of premium paid out as claims (cash basis) |
| `incurred_loss_ratio` | IncurLoss_B / EarnedPremNet_B | % of premium incurred as claims (accrual basis) |
| `ibnr_ratio` | BulkLoss_B / EarnedPremNet_B | % of premium held as IBNR reserve |
| `reserve_redundancy` | IncurLoss_B − CumPaidLoss_B | Unpaid case reserve still to be paid |
| `development_factor` | CumPaidLoss_B[lag+1] / CumPaidLoss_B[lag] | Link ratio — used to build CDF in chain-ladder |

---

## Actuarial notes on data quality

1. **Negative values:** Some `BulkLoss_B` values are negative — this is valid. It indicates the insurer released IBNR (i.e., losses developed more favourably than reserved). Do not treat as errors.

2. **Zero premium rows:** A small number of insurers show zero or near-zero premium in some years. These are transitional periods (run-off, market entry/exit). Flag with `Single=0` or exclude from per-insurer analysis.

3. **Group vs single:** Approximately 40% of rows are group insurers (`Single=0`). These have internal quota-share arrangements that affect the net premium figure. For a clean affordability analysis, filter to `Single=1` first, then run the full population as a sensitivity check.

4. **Currency:** All figures are in USD thousands ($ '000). Scale accordingly in charts and commentary.

5. **Development lag 120:** The 10th development year (120 months) represents the "ultimate" position for accident years that are fully run off. AY1998 at lag 120 = AY1998 fully developed. Use this as ground truth when validating IBNR estimates.

---

## Triangle structure example

For a single insurer (GRCODE = 353), AccidentYear 1998:

| DevelopmentLag | CumPaidLoss_B | IncurLoss_B |
|---|---|---|
| 12 | 45,200 | 82,400 |
| 24 | 68,100 | 84,100 |
| 36 | 74,800 | 81,200 |
| ... | ... | ... |
| 120 | 79,300 | 79,300 |

The convergence of paid and incurred at lag 120 confirms full development.
The "upper triangle" is lags 12–(current), used to estimate CDFs.
The "lower triangle" (actual outcomes) is used to validate your model.

---

## Analytical assumptions

### Expense ratio assumption — 28.5%

All affordability queries in `03_affordability.sql` apply an expense
load of **28.5% of net earned premium** to estimate operating costs.

This is composed of:
- Fixed expense ratio (FER): 16.0% — staff, rent, technology, overhead
- Variable expense ratio (VER): 12.5% — agent commissions, premium tax

**Source:** This assumption is consistent with the US private passenger
auto insurance industry average expense ratios published in the NAIC
Insurance Expense Exhibit and referenced in CAS Exam 5 study materials.
Individual insurers will vary — some large direct writers operate below
25%, while smaller regional insurers may exceed 35%.

**Sensitivity:** The stress test in Section D of `03_affordability.sql`
tests a +15% claims shock. A separate sensitivity on the expense
assumption is recommended — increasing expenses to 32% would reduce
the surplus by approximately 3.5 percentage points across all years.

---

## References

- Meyers, G. & Shi, P. (2011). *Loss Reserving Data Pulled from NAIC Schedule P.* CAS.
- CAS Exam 5 Study Note: Basic Ratemaking and Estimation of Claim Liabilities.
- Friedland, J. (2010). *Estimating Unpaid Claims Using Basic Techniques.* CAS.




