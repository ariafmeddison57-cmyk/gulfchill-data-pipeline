-- ==============================================================================
-- GulfChill Logistics Pipeline - Incremental Ingestion & Lineage Stacking Engine
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Domain: Fleet Dispatch Staging & Source Lineage Tracking
-- 
-- Objectives:
--   1. Combine disparate operational subsets using high-performance UNION ALL.
--   2. Inject runtime ingestion timestamps (GETDATE()) for data freshness audits.
--   3. Apply business lineage classification ('historical_record', 'livestream', 'Void').
--   4. Handle full shipment lifecycle (Delivered, Scheduled, and Cancelled dispatches).
-- ==============================================================================

USE Gulfchill;
GO

SELECT
    shipment_id,
    customer_id,
    scheduled_pickup,
    actual_pickup,
    status,
    Time_stamp,
    CASE
        WHEN status = 'Delivered' THEN 'historical_record'
        WHEN status = 'Scheduled' THEN 'livestream'
        WHEN status = 'Cancelled' THEN 'Void'
    END AS records_lineage
FROM (
    -- Stream 1: Active En-Route / Scheduled Dispatches
    SELECT
        shipment_id,
        customer_id,
        scheduled_pickup,
        actual_pickup,
        status,
        GETDATE() AS Time_stamp
    FROM dbo.shipments
    WHERE status = 'Scheduled'

    UNION ALL

    -- Stream 2: Historical Completed Deliveries
    SELECT
        shipment_id,
        customer_id,
        scheduled_pickup,
        actual_pickup,
        status,
        GETDATE() AS Time_stamp
    FROM dbo.shipments
    WHERE status = 'Delivered'

    UNION ALL

    -- Stream 3: Voided / Cancelled Orders
    SELECT
        shipment_id,
        customer_id,
        scheduled_pickup,
        actual_pickup,
        status,
        GETDATE() AS Time_stamp
    FROM dbo.shipments
    WHERE status = 'Cancelled'
) AS t
ORDER BY actual_pickup;
GO
