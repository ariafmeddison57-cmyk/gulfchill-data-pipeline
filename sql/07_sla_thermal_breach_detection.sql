-- ==============================================================================
-- GulfChill Logistics Pipeline - Automated Cold-Chain SLA Thermal Breach Engine
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Domain: Reefer Fleet IoT Telemetry & Pharmaceutical / Food Safety Compliance
-- 
-- Objectives:
--   1. Real-time consecutive ping comparison using value window functions LAG() and LEAD().
--   2. Partition by shipment_id to ensure isolated tracking per delivery journey.
--   3. Detect thermal shocks: Spikes >= +2.0C and Rapid Chills <= -2.0C.
--   4. Eliminate table self-joins for high-throughput streaming ingest.
-- ==============================================================================

USE Gulfchill;
GO

SELECT 
    reading_id,
    shipment_id,
    recorded_at,
    temp_c,
    prev_temp,
    ROUND(temp_c - prev_temp, 2) AS temp_change,
    next_temp,
    CASE 
        WHEN temp_c - prev_temp >= 2.0 THEN 'THERMAL_SPIKE_BREACH'
        WHEN temp_c - prev_temp <= -2.0 THEN 'RAPID_COOLING'
        WHEN prev_temp IS NULL THEN 'TRIP_START'
        ELSE 'NORMAL'
    END AS compliance_status
FROM (
    SELECT
        reading_id,
        shipment_id,
        recorded_at,
        temp_c,
        -- Partition by shipment_id isolates each cargo journey:
        LAG(temp_c, 1) OVER(PARTITION BY shipment_id ORDER BY recorded_at) AS prev_temp,
        LEAD(temp_c, 1) OVER(PARTITION BY shipment_id ORDER BY recorded_at) AS next_temp
    FROM dbo.temp_readings
) AS t
ORDER BY shipment_id, recorded_at;
GO
