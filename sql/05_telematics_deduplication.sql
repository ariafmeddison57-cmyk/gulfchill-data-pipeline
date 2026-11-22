-- ==============================================================================
-- GulfChill Logistics Pipeline - IoT Telematics Deduplication & Latest Status Engine
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Domain: Reefer Fleet Telemetry & IoT Sensor Ingestion
-- 
-- Objectives:
--   1. Isolate the single most recent temperature telemetry reading per shipment.
--   2. Handle high-frequency sensor ping bursts and eliminate network retries.
--   3. Leverage ROW_NUMBER() partitioned by shipment_id and sorted DESC by timestamp.
--   4. Filter in an outer projection (WHERE reading_version = 1) for staging tables.
-- ==============================================================================

USE Gulfchill;
GO

SELECT
    reading_id,
    shipment_id,
    recorded_at,
    temp_c
FROM (
    SELECT
        reading_id,
        shipment_id,
        recorded_at,
        temp_c,
        -- Sort DESC so rank 1 always represents the latest real-time status:
        ROW_NUMBER() OVER(
            PARTITION BY shipment_id 
            ORDER BY recorded_at DESC
        ) AS reading_version
    FROM dbo.temp_readings
) AS t
WHERE reading_version = 1
ORDER BY shipment_id;
GO
