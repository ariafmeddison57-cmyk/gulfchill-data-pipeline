-- ==============================================================================
-- GulfChill Logistics Data Warehouse - Advanced Analytical Window Functions
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Objectives:
--   1. Ranking Functions: Compare ROW_NUMBER(), RANK(), DENSE_RANK(), and NTILE().
--   2. Common Table Expressions (CTE): Top-N filtering per partition.
--   3. Aggregate Window Functions: Running totals and partition benchmarking without GROUP BY.
--   4. Moving Frames: Rolling maintenance cost window.
-- ==============================================================================

USE Gulfchill;
GO

-- ------------------------------------------------------------------------------
-- 1. Comparative Ranking Analysis across Partitions
-- ------------------------------------------------------------------------------
SELECT TOP 50
    customer_id,
    shipment_id,
    destination_city,
    revenue_qar,
    -- Strictly sequential row sequence (breaks ties)
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY revenue_qar DESC) AS row_num,
    -- Standard competition rank (skips ranks on ties: 1, 2, 2, 4...)
    RANK() OVER(PARTITION BY customer_id ORDER BY revenue_qar DESC) AS rnk,
    -- Dense rank (no gaps: 1, 2, 2, 3...)
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY revenue_qar DESC) AS dense_rnk,
    -- Quartile segmentation across all fleet revenue (1 = Top 25%, 4 = Bottom 25%)
    NTILE(4) OVER(ORDER BY revenue_qar DESC) AS revenue_quartile
FROM 
    dbo.shipments
ORDER BY 
    customer_id, revenue_qar DESC;
GO

-- ------------------------------------------------------------------------------
-- 2. Top-3 Shipments Per Customer via Common Table Expression (CTE)
-- ------------------------------------------------------------------------------
WITH RankedShipments AS (
    SELECT 
        customer_id,
        shipment_id,
        destination_city,
        temp_zone,
        revenue_qar,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY revenue_qar DESC) AS rank_pos
    FROM 
        dbo.shipments
)
SELECT 
    customer_id,
    rank_pos,
    shipment_id,
    destination_city,
    temp_zone,
    revenue_qar
FROM 
    RankedShipments
WHERE 
    rank_pos <= 3
ORDER BY 
    customer_id, rank_pos;
GO

-- ------------------------------------------------------------------------------
-- 3. Aggregate Window Functions: Running Totals & Partition Benchmarks
-- ------------------------------------------------------------------------------
SELECT TOP 50
    shipment_id,
    customer_id,
    scheduled_pickup,
    revenue_qar,
    -- Cumulative running total of revenue per customer over time
    SUM(revenue_qar) OVER(
        PARTITION BY customer_id 
        ORDER BY scheduled_pickup 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_customer_revenue,
    -- Customer average shipment benchmark
    AVG(revenue_qar) OVER(PARTITION BY customer_id) AS customer_avg_revenue,
    -- Shipment variance vs customer mean
    revenue_qar - AVG(revenue_qar) OVER(PARTITION BY customer_id) AS variance_from_mean,
    -- Total shipments volume count for this customer
    COUNT(shipment_id) OVER(PARTITION BY customer_id) AS customer_shipment_volume
FROM 
    dbo.shipments
ORDER BY 
    customer_id, scheduled_pickup;
GO
