-- ============================================================
--  PHASE 2 — SCRIPT 1: LOAD DATA
--  File    : sql/01_load_data.sql
--  Purpose : Create schema and load CAS Schedule P PP Auto CSV
--  Run in  : MySQL Workbench, database cas_pc_analysis
--  Data    : data/raw/ppauto_pos.csv
-- ============================================================

USE cas_pc_analysis;

-- ============================================================
-- STEP 1 — CREATE THE TABLE
-- Column names match the CAS CSV exactly
-- ============================================================

DROP TABLE IF EXISTS ppauto;

CREATE TABLE ppauto (
    GRCODE            INT             NOT NULL,
    GRNAME            VARCHAR(100)    NOT NULL,
    AccidentYear      SMALLINT        NOT NULL,
    DevelopmentYear   SMALLINT        NOT NULL,
    DevelopmentLag    SMALLINT        NOT NULL,
    IncurLoss_B       DECIMAL(15,0)   NULL,
    CumPaidLoss_B     DECIMAL(15,0)   NULL,
    BulkLoss_B        DECIMAL(15,0)   NULL,
    EarnedPremDIR_B   DECIMAL(15,0)   NULL,
    EarnedPremCeded_B DECIMAL(15,0)   NULL,
    EarnedPremNet_B   DECIMAL(15,0)   NULL,
    Single            INT             NULL,
    PostedReserve2007 DECIMAL(15,0)   NULL,
    PRIMARY KEY (GRCODE, AccidentYear, DevelopmentLag)
);

-- ============================================================
-- STEP 2 — LOAD THE CSV
-- Update the file path below to match where your file is saved
-- Use forward slashes even on Windows
-- ============================================================

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ppauto_pos.csv'
INTO TABLE ppauto
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    GRCODE,
    GRNAME,
    AccidentYear,
    DevelopmentYear,
    DevelopmentLag,
    IncurLoss_B,
    CumPaidLoss_B,
    BulkLoss_B,
    EarnedPremDIR_B,
    EarnedPremCeded_B,
    EarnedPremNet_B,
    Single,
    PostedReserve2007
);

-- ============================================================
-- STEP 3 — VALIDATE THE LOAD
-- Run these one at a time and check the numbers look right
-- ============================================================

-- How many rows loaded? Expect ~15,000–16,000
SELECT COUNT(*) AS total_rows FROM ppauto;

-- How many distinct insurers?
SELECT COUNT(DISTINCT GRCODE) AS total_insurers FROM ppauto;

-- Accident years present — should be 1998 to 2007
SELECT DISTINCT AccidentYear
FROM ppauto
ORDER BY AccidentYear;

-- Development lags present — should be 12, 24, 36 ... 120
SELECT DISTINCT DevelopmentLag
FROM ppauto
ORDER BY DevelopmentLag;

-- Quick look at first 10 rows
SELECT * FROM ppauto LIMIT 10;

-- Sanity check: are any premium values negative or zero?
SELECT
    COUNT(*)                            AS total_rows,
    SUM(EarnedPremNet_B <= 0)           AS zero_or_neg_premium,
    SUM(CumPaidLoss_B < 0)              AS negative_paid,
    SUM(BulkLoss_B < 0)                 AS negative_ibnr,
    SUM(IncurLoss_B IS NULL)            AS null_incurred
FROM ppauto;

SELECT
    Single,
    COUNT(*)                      AS rw,
    SUM(EarnedPremNet_B <= 0)     AS zero_or_neg_premium
FROM ppauto
GROUP BY Single;

SELECT DISTINCT Single
FROM ppauto
ORDER BY Single
LIMIT 20;

SELECT DISTINCT Single FROM ppauto ORDER BY Single;

SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT GRCODE)          AS total_insurers,
    MIN(AccidentYear)               AS first_accident_year,
    MAX(AccidentYear)               AS last_accident_year,
    SUM(EarnedPremNet_B <= 0)       AS zero_or_neg_premium,
    SUM(CumPaidLoss_B < 0)          AS negative_paid,
    SUM(BulkLoss_B < 0)             AS negative_ibnr,
    SUM(IncurLoss_B IS NULL)        AS null_incurred
FROM ppauto;

SELECT
    Single,
    COUNT(*)                        AS rw,
    SUM(EarnedPremNet_B <= 0)       AS zero_or_neg_premium
FROM ppauto
GROUP BY Single;