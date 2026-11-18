-- ==============================================================================
-- GulfChill Logistics Pipeline - Production System Reconciliation Engine
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Domain: Transport Management System (TMS) vs. Financial ERP Billing Audit
-- 
-- Objectives:
--   1. Two-way reconciliation using FULL OUTER JOIN to capture all data skew.
--   2. Defensive primary key resolution using COALESCE(s.shipment_id, i.shipment_id).
--   3. Audit classification: MATCHED, MISSING_INVOICE, and ORPHAN_INVOICE.
--   4. Financial state attribution without false positive assumptions.
-- ==============================================================================

USE Gulfchill;
GO

SELECT
    -- 1. Defensive ID extraction: captures ID even if orphan record exists
    COALESCE(s.shipment_id, i.shipment_id) AS shipment_id,
    i.invoice_id,
    s.status AS shipment_status,
    i.paid_date,
    
    -- 2. System Reconciliation Audit Category
    CASE
        WHEN s.shipment_id IS NOT NULL AND i.invoice_id IS NOT NULL THEN 'MATCHED'
        WHEN s.shipment_id IS NOT NULL AND i.invoice_id IS NULL THEN 'MISSING_INVOICE'
        WHEN s.shipment_id IS NULL AND i.invoice_id IS NOT NULL THEN 'ORPHAN_INVOICE'
    END AS reconciliation_category,
    
    -- 3. Accurate Financial & Billing State
    CASE 
        WHEN i.invoice_id IS NULL AND s.status = 'Cancelled' THEN 'CANCELLED_NO_BILL'
        WHEN i.invoice_id IS NULL THEN 'UNBILLED_ACTIVE'
        WHEN i.paid_date IS NOT NULL THEN 'PAID'
        ELSE 'UNPAID'
    END AS billing_state

FROM dbo.shipments AS s
FULL JOIN dbo.invoices AS i 
    ON s.shipment_id = i.shipment_id;
GO
