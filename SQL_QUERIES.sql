-- ============================================================
-- CUSTOMER CHURN ANALYSIS - SQL QUERIES
-- ============================================================
-- This file contains all SQL queries used in the analysis
-- Database: SQLite
-- Table: customers (CustomerID, Tenure, Contract, MonthlyCharges, Churn)
-- ============================================================

-- ------------------------------------------------------------
-- QUERY 1: OVERALL CHURN RATE
-- ------------------------------------------------------------
-- Calculate overall churn metrics across entire customer base

SELECT 
    COUNT(CASE WHEN Churn='Yes' THEN 1 END) * 100.0 / COUNT(*) as ChurnRate,
    COUNT(CASE WHEN Churn='Yes' THEN 1 END) as ChurnedCustomers,
    COUNT(CASE WHEN Churn='No' THEN 1 END) as ActiveCustomers,
    COUNT(*) as TotalCustomers
FROM customers;

/* Results:
   ChurnRate: 31.51%
   ChurnedCustomers: 2,206
   ActiveCustomers: 4,794
   TotalCustomers: 7,000
*/


-- ------------------------------------------------------------
-- QUERY 2: CHURN RATE BY CONTRACT TYPE
-- ------------------------------------------------------------
-- Analyze churn patterns across different contract types

SELECT 
    Contract,
    AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) * 100 as ChurnRate,
    COUNT(*) as TotalCustomers,
    COUNT(CASE WHEN Churn='Yes' THEN 1 END) as ChurnedCustomers
FROM customers 
GROUP BY Contract
ORDER BY ChurnRate DESC;

/* Results:
   Month-to-Month: 44.6% churn (3,925 customers, 1,750 churned)
   One Year: 19.9% churn (1,695 customers, 337 churned)
   Two Year: 8.6% churn (1,380 customers, 119 churned)
*/


-- ------------------------------------------------------------
-- QUERY 3: CHURN RATE BY TENURE SEGMENTS
-- ------------------------------------------------------------
-- Analyze how customer tenure affects churn probability

SELECT 
    CASE 
        WHEN Tenure < 6 THEN '0-6 months'
        WHEN Tenure < 12 THEN '6-12 months'
        WHEN Tenure < 24 THEN '12-24 months'
        WHEN Tenure < 48 THEN '24-48 months'
        ELSE '48+ months'
    END as TenureSegment,
    AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) * 100 as ChurnRate,
    COUNT(*) as TotalCustomers,
    COUNT(CASE WHEN Churn='Yes' THEN 1 END) as ChurnedCustomers
FROM customers 
GROUP BY TenureSegment
ORDER BY 
    CASE 
        WHEN TenureSegment = '0-6 months' THEN 1
        WHEN TenureSegment = '6-12 months' THEN 2
        WHEN TenureSegment = '12-24 months' THEN 3
        WHEN TenureSegment = '24-48 months' THEN 4
        ELSE 5
    END;

/* Results:
   0-6 months: 42.4% churn
   6-12 months: 33.5% churn
   12-24 months: 29.5% churn
   24-48 months: 19.7% churn
   48+ months: 17.2% churn
   
   Insight: Clear inverse relationship - longer tenure = lower churn
*/


-- ------------------------------------------------------------
-- QUERY 4: REVENUE AT RISK ANALYSIS
-- ------------------------------------------------------------
-- Calculate financial impact of customer churn

SELECT 
    Churn,
    COUNT(*) as Customers,
    ROUND(SUM(MonthlyCharges), 2) as TotalMonthlyRevenue,
    ROUND(AVG(MonthlyCharges), 2) as AvgMonthlyCharge,
    ROUND(SUM(MonthlyCharges * 12), 2) as AnnualRevenue
FROM customers 
GROUP BY Churn;

/* Results:
   Active: $3,330,594 annual revenue
   Churned: $1,684,561 annual revenue at risk
   
   Insight: Churned customers represent $1.68M in lost annual revenue
*/


-- ------------------------------------------------------------
-- QUERY 5: HIGH-RISK CUSTOMER IDENTIFICATION
-- ------------------------------------------------------------
-- Identify customer segments with churn rate > 30%

SELECT 
    Contract,
    CASE 
        WHEN Tenure < 6 THEN 'New (0-6 months)'
        WHEN Tenure < 24 THEN 'Medium (6-24 months)'
        ELSE 'Long-term (24+ months)'
    END as TenureCategory,
    COUNT(*) as Customers,
    ROUND(AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) * 100, 2) as ChurnRate,
    ROUND(SUM(CASE WHEN Churn='Yes' THEN MonthlyCharges ELSE 0 END), 2) as MonthlyRevenueAtRisk
FROM customers 
GROUP BY Contract, TenureCategory
HAVING ChurnRate > 30
ORDER BY ChurnRate DESC;

/* Results - Critical Segments:
   1. Month-to-Month + New: 59.4% churn, $58,458/month at risk
   2. Month-to-Month + Medium: 44.0% churn, $36,408/month at risk
   
   Insight: These two segments require immediate intervention
*/


-- ------------------------------------------------------------
-- QUERY 6: CHURN BY MONTHLY CHARGE BRACKETS
-- ------------------------------------------------------------
-- Analyze relationship between pricing and churn

SELECT 
    CASE 
        WHEN MonthlyCharges < 40 THEN '$0-40'
        WHEN MonthlyCharges < 60 THEN '$40-60'
        WHEN MonthlyCharges < 80 THEN '$60-80'
        ELSE '$80+'
    END as ChargeBracket,
    COUNT(*) as Customers,
    ROUND(AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) * 100, 2) as ChurnRate,
    ROUND(AVG(MonthlyCharges), 2) as AvgCharge
FROM customers 
GROUP BY ChargeBracket
ORDER BY AvgCharge;

/* Results:
   $0-40: 21.6% churn
   $40-60: 28.7% churn
   $60-80: 31.9% churn
   $80+: 48.3% churn
   
   Insight: Clear positive correlation - higher price = higher churn
   Suggests price sensitivity, especially in premium tier ($80+)
*/


-- ------------------------------------------------------------
-- BONUS QUERY 7: MULTI-DIMENSIONAL RISK SEGMENTATION
-- ------------------------------------------------------------
-- Comprehensive risk matrix combining contract, tenure, and pricing

SELECT 
    Contract,
    CASE 
        WHEN Tenure < 12 THEN 'New'
        WHEN Tenure < 36 THEN 'Medium'
        ELSE 'Loyal'
    END as TenureGroup,
    CASE 
        WHEN MonthlyCharges < 50 THEN 'Budget'
        WHEN MonthlyCharges < 70 THEN 'Standard'
        ELSE 'Premium'
    END as PriceGroup,
    COUNT(*) as Customers,
    ROUND(AVG(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) * 100, 1) as ChurnRate,
    ROUND(SUM(MonthlyCharges), 2) as MonthlyRevenue
FROM customers
GROUP BY Contract, TenureGroup, PriceGroup
HAVING Customers >= 50  -- Exclude small segments
ORDER BY ChurnRate DESC
LIMIT 10;

/* This query identifies the most granular high-risk segments
   Useful for targeted retention campaigns
*/


-- ============================================================
-- KEY INSIGHTS SUMMARY
-- ============================================================
/*
1. CONTRACT TYPE IMPACT:
   - Month-to-Month contracts have 5.2x higher churn than Two Year
   - 56% of customer base is on high-risk Month-to-Month contracts

2. TENURE IMPACT:
   - New customers (0-6 months) have 2.5x higher churn than loyal (48+ months)
   - First 6 months are critical retention window

3. REVENUE IMPACT:
   - $1.68M annual revenue at risk from churned customers
   - Average churned customer pays $63.64/month (higher than average)

4. HIGH-RISK SEGMENTS:
   - Month-to-Month + New: 59.4% churn (1,493 customers)
   - Month-to-Month + Medium tenure: 44.0% churn (1,235 customers)

5. PRICING SENSITIVITY:
   - Premium tier ($80+) shows 48.3% churn
   - Budget tier ($0-40) shows only 21.6% churn
   - Clear price sensitivity pattern

6. RETENTION OPPORTUNITIES:
   - Converting Month-to-Month to annual contracts
   - Enhanced onboarding for new customers
   - Pricing optimization for premium tier
   - Proactive intervention for high-risk segments
*/
