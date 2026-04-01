-- ============================================================
--  PHASE 2 — SCRIPT 2: EXPLORATORY DATA ANALYSIS
--  File    : sql/02_eda_queries.sql
--  Purpose : Explore the CAS Schedule P PP Auto dataset
--            Understand the portfolio before modelling
--  Run in  : MySQL Workbench, database cas_pc_analysis
-- ============================================================

USE cas_pc_analysis;

-- ============================================================
-- SECTION A — PORTFOLIO OVERVIEW
-- ============================================================

-- A1. Total premium and claims across all years
SELECT
    SUM(EarnedPremNet_B)            AS total_earned_premium,
    SUM(CumPaidLoss_B)              AS total_paid_losses,
    SUM(IncurLoss_B)                AS total_incurred_losses,
    SUM(BulkLoss_B)                 AS total_ibnr_reserves,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1)  AS paid_loss_ratio_pct,
    ROUND(SUM(IncurLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1)  AS incurred_loss_ratio_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0;


-- A2. Portfolio size by accident year
-- Are premiums growing or shrinking over time?
SELECT
    AccidentYear,
    COUNT(DISTINCT GRCODE)                           AS active_insurers,
    SUM(EarnedPremNet_B)                             AS total_net_premium,
    SUM(CumPaidLoss_B)                               AS total_paid_losses,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1)  AS paid_loss_ratio_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- A3. Top 10 insurers by total net earned premium
-- Who are the biggest players in this dataset?
SELECT
    GRCODE,
    GRNAME,
    SUM(EarnedPremNet_B)                             AS total_net_premium,
    SUM(CumPaidLoss_B)                               AS total_paid_losses,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1)  AS paid_loss_ratio_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY GRCODE, GRNAME
ORDER BY total_net_premium DESC
LIMIT 10;

SELECT 
    AccidentYear,
    MAX(DevelopmentLag) AS max_lag
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- ============================================================
-- SECTION B — LOSS RATIO ANALYSIS
-- The core metric: what % of premium is paid out as claims?
-- ============================================================

-- B1. Industry average loss ratio by accident year
-- Watch for deterioration — rising loss ratios = pricing problem
SELECT
    AccidentYear,
    ROUND(AVG(CumPaidLoss_B
        / NULLIF(EarnedPremNet_B, 0)) * 100, 1)     AS avg_paid_lr_pct,
    ROUND(AVG(IncurLoss_B
        / NULLIF(EarnedPremNet_B, 0)) * 100, 1)     AS avg_incurred_lr_pct,
    ROUND(MIN(CumPaidLoss_B
        / NULLIF(EarnedPremNet_B, 0)) * 100, 1)     AS min_paid_lr_pct,
    ROUND(MAX(CumPaidLoss_B
        / NULLIF(EarnedPremNet_B, 0)) * 100, 1)     AS max_paid_lr_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- B2. Loss ratio distribution — how spread out are insurers?
-- Buckets tell you whether the market is consistent or fragmented
SELECT
    CASE
        WHEN CumPaidLoss_B / EarnedPremNet_B < 0.40  THEN 'Under 40%'
        WHEN CumPaidLoss_B / EarnedPremNet_B < 0.55  THEN '40% to 55%'
        WHEN CumPaidLoss_B / EarnedPremNet_B < 0.70  THEN '55% to 70%'
        WHEN CumPaidLoss_B / EarnedPremNet_B < 0.85  THEN '70% to 85%'
        WHEN CumPaidLoss_B / EarnedPremNet_B < 1.00  THEN '85% to 100%'
        ELSE 'Over 100%'
    END                                               AS loss_ratio_bucket,
    COUNT(*)                                          AS insurer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY loss_ratio_bucket
ORDER BY MIN(CumPaidLoss_B / EarnedPremNet_B);


-- B3. Worst performing insurers — loss ratio over 90% at full development
-- These are the companies that could not pay their claims from premium alone
SELECT
    GRCODE,
    GRNAME,
    AccidentYear,
    EarnedPremNet_B                                  AS net_premium,
    CumPaidLoss_B                                    AS paid_losses,
    ROUND(CumPaidLoss_B
        / NULLIF(EarnedPremNet_B, 0) * 100, 1)       AS paid_loss_ratio_pct,
    CumPaidLoss_B - EarnedPremNet_B                  AS surplus_deficit
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
AND CumPaidLoss_B / EarnedPremNet_B > 0.90
ORDER BY paid_loss_ratio_pct DESC
LIMIT 20;


-- ============================================================
-- SECTION C — LOSS DEVELOPMENT
-- How do losses grow over time as claims are reported and paid?
-- This feeds directly into the chain-ladder analysis in R
-- ============================================================

-- C1. Industry average cumulative paid losses by development lag
-- You should see losses grow then flatten as claims settle
SELECT
    DevelopmentLag,
    COUNT(DISTINCT GRCODE)                          AS insurers,
    ROUND(AVG(CumPaidLoss_B), 0)                    AS avg_cum_paid,
    ROUND(AVG(IncurLoss_B), 0)                      AS avg_incurred,
    ROUND(AVG(BulkLoss_B), 0)                       AS avg_ibnr_reserve,
    ROUND(AVG(CumPaidLoss_B)
        / NULLIF(AVG(IncurLoss_B), 0) * 100, 1)    AS pct_paid_of_incurred
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
GROUP BY DevelopmentLag
ORDER BY DevelopmentLag;


-- C2. Development link ratios (chain-ladder building block)
-- Each ratio shows how much losses grew from one lag to the next
-- These become the CDFs used to project ultimate losses
SELECT
    a.DevelopmentLag                                AS from_lag,
    a.DevelopmentLag + 1                            AS to_lag,
    ROUND(SUM(b.CumPaidLoss_B)
        / NULLIF(SUM(a.CumPaidLoss_B), 0), 4)      AS volume_wtd_link_ratio
FROM ppauto a
JOIN ppauto b
    ON  a.GRCODE       = b.GRCODE
    AND a.AccidentYear = b.AccidentYear
    AND b.DevelopmentLag = a.DevelopmentLag + 1
WHERE a.Single = 1
AND a.EarnedPremNet_B > 0
AND a.CumPaidLoss_B > 0
GROUP BY a.DevelopmentLag
ORDER BY a.DevelopmentLag;


-- ============================================================
-- SECTION D — AFFORDABILITY SIGNALS
-- Early warning: which insurers show stress signs?
-- ============================================================

-- D1. Insurers where paid losses exceed net premium in any year
-- These companies paid out more in claims than they collected
-- in premium — a direct affordability failure signal
SELECT
    GRCODE,
    GRNAME,
    AccidentYear,
    EarnedPremNet_B                                 AS net_premium,
    CumPaidLoss_B                                   AS paid_losses,
    CumPaidLoss_B - EarnedPremNet_B                 AS deficit,
    ROUND(CumPaidLoss_B
        / NULLIF(EarnedPremNet_B, 0) * 100, 1)      AS loss_ratio_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 120
AND CumPaidLoss_B > EarnedPremNet_B
ORDER BY deficit DESC;


-- D2. IBNR as a % of incurred losses by accident year
-- High IBNR % = high uncertainty = more reserve risk
SELECT
    AccidentYear,
    ROUND(AVG(BulkLoss_B
        / NULLIF(IncurLoss_B, 0)) * 100, 1)        AS avg_ibnr_pct_of_incurred,
    SUM(BulkLoss_B)                                 AS total_ibnr,
    SUM(IncurLoss_B)                                AS total_incurred
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 12         -- early development — most uncertainty here
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- D3. Summary affordability scorecard per insurer
-- One row per insurer showing their overall position
-- This is the table we export to R for deeper analysis
SELECT
    GRCODE,
    GRNAME,
    COUNT(DISTINCT AccidentYear)                    AS years_active,
    SUM(EarnedPremNet_B)                            AS total_premium,
    SUM(CumPaidLoss_B)                              AS total_paid,
    SUM(BulkLoss_B)                                 AS total_ibnr,
    SUM(IncurLoss_B)                                AS total_incurred,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1) AS overall_paid_lr,
    ROUND(SUM(IncurLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1) AS overall_incurred_lr,
    CASE
        WHEN SUM(CumPaidLoss_B)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 1.0  THEN 'DEFICIT'
        WHEN SUM(CumPaidLoss_B)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 0.85 THEN 'AT RISK'
        WHEN SUM(CumPaidLoss_B)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 0.70 THEN 'WATCH'
        ELSE                                              'ADEQUATE'
    END                                             AS affordability_flag
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 120
GROUP BY GRCODE, GRNAME
ORDER BY overall_paid_lr DESC;
