-- ==============================================================================
-- GulfChill Logistics Data Warehouse - Accounts Receivable Aging Engine
-- Author: Ariaf Meddison (@ariafmeddison57-cmyk)
-- Objectives:
--   1. Handle NULL payment dates dynamically via COALESCE with current system date.
--   2. Calculate overdue/lead days via DATEDIFF against payment terms.
--   3. Classify aging buckets via multi-branch CASE WHEN logic.
--   4. Standardize audit labeling via CONCAT formatting.
-- ==============================================================================

USE Gulfchill;
GO

SELECT
    invoice_id,
    customer_id,
    amount_qar,
    due_date,
    realpaid_date,
    DATEDIFF(DAY, due_date, realpaid_date) AS due_days,
    CASE
        WHEN paid_date IS NULL THEN 'Still Unpaid'
        WHEN DATEDIFF(DAY, due_date, realpaid_date) > 0 THEN 'Paid Late'
        WHEN DATEDIFF(DAY, due_date, realpaid_date) < 0 THEN 'Paid Early'
        ELSE 'Paid On Time'
    END AS invoice_status,
    CONCAT('#', invoice_id, ' - QAR ', CAST(amount_qar AS VARCHAR(20))) AS formatted_label
FROM
    (SELECT 
        invoice_id,
        shipment_id,
        customer_id,
        invoice_date,
        paid_date,
        due_date,
        amount_qar,
        COALESCE(paid_date, CAST(GETDATE() AS DATE)) AS realpaid_date
    FROM 
        dbo.invoices
    ) AS t
ORDER BY 
    due_days DESC;
GO
