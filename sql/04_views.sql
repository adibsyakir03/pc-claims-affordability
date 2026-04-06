-- ============================================================
--  PHASE 2 — SCRIPT 4: EXECUTIVE SUMMARY VIEWS
--  File    : sql/04_views.sql
--  Purpose : Create permanent views that R and Python query
--            directly — the bridge between SQL and analysis
--  Run in  : MySQL Workbench, database cas_pc_analysis
-- ============================================================

USE cas_pc_analysis;

-- ============================================================
-- VIEW 1 — INDUSTRY SUMMARY
-- One row per accident year
-- Used by: R rate adequacy, Python trend charts
-- ============================================================

CREATE OR REPLACE VIEW v_industry_summary AS
SELECT
    AccidentYear,
    COUNT(DISTINCT GRCODE)                              AS active_insurers,
    SUM(EarnedPremNet_B)                                AS earned_premium,
    SUM(CumPaidLoss_B)                                  AS paid_claims,
    SUM(IncurLoss_B)                                    AS incurred_claims,
    SUM(BulkLoss_B)                                     AS ibnr_reserves,
    ROUND(SUM(EarnedPremNet_B) * 0.285, 0)              AS estimated_expenses,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS paid_loss_ratio,
    ROUND(SUM(IncurLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS incurred_loss_ratio,
    ROUND((SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS combined_ratio,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS funding_surplus_deficit,
    ROUND((SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS surplus_deficit_pct,
    -- Stress test: +15% severity shock
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B) * 1.15
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS stressed_surplus_deficit,
    CASE
        WHEN SUM(EarnedPremNet_B)
            >= SUM(CumPaidLoss_B) * 1.15
            + SUM(EarnedPremNet_B) * 0.285
        THEN 'PASSES'
        ELSE 'FAILS'
    END                                                 AS stress_test_result,
    CASE
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            <= SUM(EarnedPremNet_B)
        THEN 'FUNDED'
        ELSE 'UNDERFUNDED'
    END                                                 AS affordability_status
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY AccidentYear;


-- ============================================================
-- VIEW 2 — INSURER SCORECARD
-- One row per insurer, full 10-year picture
-- Used by: R IBNR analysis, Python affordability charts
-- ============================================================

CREATE OR REPLACE VIEW v_insurer_scorecard AS
SELECT
    GRCODE,
    GRNAME,
    COUNT(DISTINCT AccidentYear)                        AS years_active,
    SUM(EarnedPremNet_B)                                AS total_premium,
    SUM(CumPaidLoss_B)                                  AS total_paid_claims,
    SUM(IncurLoss_B)                                    AS total_incurred,
    SUM(BulkLoss_B)                                     AS total_ibnr,
    ROUND(SUM(EarnedPremNet_B) * 0.285, 0)              AS total_expenses,
    ROUND(SUM(CumPaidLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS paid_loss_ratio,
    ROUND(SUM(IncurLoss_B)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS incurred_loss_ratio,
    ROUND((SUM(CumPaidLoss_B)
        + SUM(EarnedPremNet_B) * 0.285)
        / NULLIF(SUM(EarnedPremNet_B), 0) * 100, 2)    AS combined_ratio,
    ROUND(SUM(EarnedPremNet_B)
        - SUM(CumPaidLoss_B)
        - SUM(EarnedPremNet_B) * 0.285, 0)              AS net_surplus_deficit,
    -- Stress test result
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
    END                                                 AS stress_test_result,
    -- Solvency status
    CASE
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 1.10
        THEN 'SEVERE DEFICIT'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 1.00
        THEN 'DEFICIT'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 0.95
        THEN 'AT RISK'
        WHEN (SUM(CumPaidLoss_B)
            + SUM(EarnedPremNet_B) * 0.285)
            / NULLIF(SUM(EarnedPremNet_B), 0) > 0.85
        THEN 'WATCH'
        ELSE 'SOLVENT'
    END                                                 AS solvency_status
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
AND DevelopmentLag = 10
GROUP BY GRCODE, GRNAME;


-- ============================================================
-- VIEW 3 — DEVELOPMENT CURVE
-- Loss development pattern across all 10 lags
-- Used by: R chain-ladder, Python development chart
-- ============================================================

CREATE OR REPLACE VIEW v_development_curve AS
SELECT
    DevelopmentLag,
    COUNT(DISTINCT GRCODE)                              AS insurers,
    ROUND(AVG(CumPaidLoss_B), 2)                        AS avg_cum_paid,
    ROUND(AVG(IncurLoss_B), 2)                          AS avg_incurred,
    ROUND(AVG(BulkLoss_B), 2)                           AS avg_ibnr,
    ROUND(AVG(CumPaidLoss_B)
        / NULLIF(AVG(IncurLoss_B), 0) * 100, 2)        AS pct_paid_of_incurred,
    ROUND(AVG(EarnedPremNet_B), 2)                      AS avg_premium,
    ROUND(AVG(CumPaidLoss_B)
        / NULLIF(AVG(EarnedPremNet_B), 0) * 100, 2)    AS avg_paid_loss_ratio
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
GROUP BY DevelopmentLag
ORDER BY DevelopmentLag;


-- ============================================================
-- VIEW 4 — LOSS TRIANGLE (wide format)
-- Paid losses by accident year and development lag
-- Used by: R ChainLadder package directly
-- ============================================================

CREATE OR REPLACE VIEW v_loss_triangle AS
SELECT
    AccidentYear,
    SUM(CASE WHEN DevelopmentLag = 1  THEN CumPaidLoss_B END) AS lag_1,
    SUM(CASE WHEN DevelopmentLag = 2  THEN CumPaidLoss_B END) AS lag_2,
    SUM(CASE WHEN DevelopmentLag = 3  THEN CumPaidLoss_B END) AS lag_3,
    SUM(CASE WHEN DevelopmentLag = 4  THEN CumPaidLoss_B END) AS lag_4,
    SUM(CASE WHEN DevelopmentLag = 5  THEN CumPaidLoss_B END) AS lag_5,
    SUM(CASE WHEN DevelopmentLag = 6  THEN CumPaidLoss_B END) AS lag_6,
    SUM(CASE WHEN DevelopmentLag = 7  THEN CumPaidLoss_B END) AS lag_7,
    SUM(CASE WHEN DevelopmentLag = 8  THEN CumPaidLoss_B END) AS lag_8,
    SUM(CASE WHEN DevelopmentLag = 9  THEN CumPaidLoss_B END) AS lag_9,
    SUM(CASE WHEN DevelopmentLag = 10 THEN CumPaidLoss_B END) AS lag_10
FROM ppauto
WHERE Single = 1
AND EarnedPremNet_B > 0
GROUP BY AccidentYear
ORDER BY AccidentYear;


-- ============================================================
-- VERIFY ALL VIEWS CREATED SUCCESSFULLY
-- ============================================================

SHOW FULL TABLES IN cas_pc_analysis WHERE TABLE_TYPE = 'VIEW';

-- Quick preview of each view
SELECT * FROM v_industry_summary      ORDER BY AccidentYear;
SELECT * FROM v_insurer_scorecard     ORDER BY combined_ratio DESC LIMIT 10;
SELECT * FROM v_development_curve     ORDER BY DevelopmentLag;
SELECT * FROM v_loss_triangle         ORDER BY AccidentYear;
