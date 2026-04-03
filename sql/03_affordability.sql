-- ============================================================
--  PHASE 2 — SCRIPT 3: CLAIMS AFFORDABILITY ANALYSIS
--  File    : sql/03_affordability.sql
--  Purpose : Formal actuarial test — can current premium intake
--            fund current paid claims + IBNR obligations?
--  Run in  : MySQL Workbench, database cas_pc_analysis
-- ============================================================

USE cas_pc_analysis;

-- ============================================================
-- SECTION A — PREMIUM ADEQUACY BY ACCIDENT YEAR
-- Core question: did premium collected cover claims incurred?
-- We use DevelopmentLag = 10 for fully developed positions
-- ============================================================

-- A1. Industry-level premium vs claims summary
-- The top-line affordability test for the entire dataset
SELECT
    AccidentYear,
    SUM(EarnedPremNet_B)                            AS earned_premium,
    SUM(CumPaidLoss_B)                              AS paid_claims,
    SUM(IncurLoss_B)                                AS incurred_claims,
    SUM(BulkLoss_B)                                 AS ibnr_reserves,
    -- Operating expense load: 28.5% of premium (industry standard)
    ROUND(SUM(EarnedPremNet_B) * 0.285, 0)          AS estimated_expenses,
    -- Total outflows: claims + expenses
    ROUND(SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285, 0)          AS total_outflows,
    -- Funding surplus or deficit
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)          AS funding_surplus_deficit,
    -- Combined ratio: claims + expenses / premium
    ROUND((SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1) AS combined_ratio_pct,
    CASE
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            <= SUM(EarnedPremNet_B) THEN 'FUNDED'
        ELSE 'UNDERFUNDED'
    END                                             AS affordability_status
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- A2. Funding gap in dollar terms by accident year
-- How much money was the industry short — or surplus — each year?
SELECT
    AccidentYear,
    ROUND(SUM(EarnedPremNet_B), 0)                  AS earned_premium,
    ROUND(SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285, 0)          AS total_outflows,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)          AS funding_surplus_deficit,
    ROUND((SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1) AS surplus_deficit_pct
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- ============================================================
-- SECTION B — INSURER LEVEL AFFORDABILITY
-- Which specific insurers can and cannot fund their claims?
-- ============================================================

-- B1. Full affordability test per insurer
-- Adds expense load to paid claims and tests against premium
SELECT
    GRCODE,
    GRNAME,
    SUM(EarnedPremNet_B)                            AS total_premium,
    SUM(CumPaidLoss_B)                              AS total_paid_claims,
    ROUND(SUM(EarnedPremNet_B) * 0.285, 0)          AS total_expenses,
    ROUND(SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285, 0)          AS total_outflows,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)          AS net_surplus_deficit,
    ROUND((SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 1) AS combined_ratio_pct,
    CASE
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 1.10 THEN 'SEVERE DEFICIT'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 1.00 THEN 'DEFICIT'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 0.95 THEN 'AT RISK'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B) ,0) > 0.85 THEN 'WATCH'
        ELSE 'SOLVENT'
    END                                             AS solvency_status
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY GRCODE, GRNAME
ORDER BY combined_ratio_pct DESC;


-- B2. Count of insurers by solvency status
-- Summary of the B1 results
SELECT
    solvency_status,
    COUNT(*)                                        AS insurer_count,
    ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(), 1)                  AS pct_of_total
FROM (
    SELECT
        GRCODE,
        CASE
            WHEN (SUM(CumPaidLoss_B)
                + SUM(EarnedPremNet_B) * 0.285)
                / NULLIF(SUM(EarnedPremNet_B), 0) > 1.10 THEN 'SEVERE DEFICIT'
            WHEN (SUM(CumPaidLoss_B)
                + SUM(EarnedPremNet_B) * 0.285)
                / NULLIF(SUM(EarnedPremNet_B), 0) > 1.00 THEN 'DEFICIT'
            WHEN (SUM(CumPaidLoss_B)
                + SUM(EarnedPremNet_B) * 0.285)
                / NULLIF(SUM(EarnedPremNet_B), 0) > 0.95 THEN 'AT RISK'
            WHEN (SUM(CumPaidLoss_B)
                + SUM(EarnedPremNet_B) * 0.285)
                / NULLIF(SUM(EarnedPremNet_B), 0) > 0.85 THEN 'WATCH'
            ELSE 'SOLVENT'
        END AS solvency_status
    FROM ppauto
    WHERE Single = 1
    AND EarnedPremNet_B > 0
    AND DevelopmentLag = 10
    GROUP BY GRCODE
) AS insurer_status
GROUP BY solvency_status
ORDER BY MIN(
    CASE solvency_status
        WHEN 'SEVERE DEFICIT' THEN 1
        WHEN 'DEFICIT'        THEN 2
        WHEN 'AT RISK'        THEN 3
        WHEN 'WATCH'          THEN 4
        ELSE 5
    END
);


-- ============================================================
-- SECTION C — IBNR AFFORDABILITY
-- Can premium also cover IBNR — the claims not yet reported?
-- This is the ultimate affordability test
-- ============================================================

-- C1. Ultimate affordability — premium vs paid + IBNR + expenses
-- The most conservative and complete test
SELECT
    AccidentYear,
    ROUND(SUM(EarnedPremNet_B), 0)                  AS earned_premium,
    ROUND(SUM(CumPaidLoss_B), 0)                    AS paid_claims,
    ROUND(SUM(BulkLoss_B), 0)                       AS ibnr_reserves,
    ROUND(SUM(EarnedPremNet_B) * 0.285, 0)          AS expenses,
    -- Total ultimate obligation
    ROUND(SUM(CumPaidLoss_B)
        + SUM(BulkLoss_B)
        + SUM(EarnedPremNet_B) * 0.285, 0)          AS total_ultimate_obligation,
    -- Can premium fund everything?
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(BulkLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)          AS residual_after_all,
    CASE
        WHEN SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B)
            + SUM(BulkLoss_B)
            + SUM(EarnedPremNet_B) * 0.285
        THEN 'FULLY FUNDED'
        ELSE 'SHORTFALL'
    END                                             AS ultimate_affordability
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 1          -- lag 1: maximum uncertainty, highest IBNR
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- ============================================================
-- SECTION D — STRESS TEST
-- What if severity increases 15% beyond expectations?
-- Regulatory requirement: test resilience under adverse scenarios
-- ============================================================

-- D1. Stressed affordability — +15% severity shock on paid claims
SELECT
    AccidentYear,
    ROUND(SUM(EarnedPremNet_B), 0)                      AS earned_premium,
    -- Base case
    ROUND(SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285, 0)              AS base_total_outflows,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS base_surplus_deficit,
    -- Stressed case: paid claims +15%
    ROUND(SUM(CumPaidLoss_B) * 1.15
        + SUM(EarnedPremNet_B) * 0.285, 0)              AS stressed_total_outflows,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B) * 1.15
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS stressed_surplus_deficit,
    CASE
        WHEN SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B) * 1.15
            + SUM(EarnedPremNet_B) * 0.285
        THEN 'PASSES STRESS TEST'
        ELSE 'FAILS STRESS TEST'
    END                                                 AS stress_test_result
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- D2. Insurer level stress test
-- Which individual insurers fail under the +15% severity scenario?
SELECT
    GRCODE,
    GRNAME,
    ROUND(SUM(EarnedPremNet_B), 0)                      AS total_premium,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS base_surplus_deficit,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B) * 1.15
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS stressed_surplus_deficit,
    CASE
        WHEN SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285
        AND SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B) * 1.15
            + SUM(EarnedPremNet_B) * 0.285
        THEN 'Passes base and stress'
        WHEN SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285
        AND SUM(EarnedPremNet_B)
            < SUM(CumPaidLoss_B) * 1.15
            + SUM(EarnedPremNet_B) * 0.285
        THEN 'Passes base — fails stress'
        ELSE 'Fails base and stress'
    END                                                 AS stress_test_result
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY GRCODE, GRNAME
ORDER BY stressed_surplus_deficit ASC;
