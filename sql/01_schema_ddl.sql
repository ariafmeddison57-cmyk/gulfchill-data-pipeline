-- ==============================================================================
-- GulfChill Logistics Data Warehouse - Core Relational Schema DDL
-- Database Engine: Microsoft SQL Server
-- Domain: Cold-Chain Logistics, Fleet Telematics & Financial Settlement
-- ==============================================================================

USE Gulfchill;
GO

-- 1. Dimension: Customers
CREATE TABLE dbo.customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(150) NOT NULL,
    industry NVARCHAR(100) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    contract_tier NVARCHAR(50) NOT NULL,     -- 'Gold', 'Silver', 'Bronze'
    credit_days INT NOT NULL DEFAULT 30,
    signup_date DATE NOT NULL
);
GO

-- 2. Dimension: Warehouses (Cold Storage Hubs)
CREATE TABLE dbo.warehouses (
    warehouse_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(150) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    capacity_sqm INT NOT NULL,
    temp_zones NVARCHAR(100) NOT NULL       -- 'Deep Frozen', 'Chilled', 'Ambient'
);
GO

-- 3. Dimension: Fleet Drivers
CREATE TABLE dbo.drivers (
    driver_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(150) NOT NULL,
    hire_date DATE NOT NULL,
    home_warehouse_id INT FOREIGN KEY REFERENCES dbo.warehouses(warehouse_id)
);
GO

-- 4. Dimension: Refrigerated Fleet Vehicles
CREATE TABLE dbo.vehicles (
    vehicle_id INT IDENTITY(1,1) PRIMARY KEY,
    plate_number NVARCHAR(50) NOT NULL UNIQUE,
    vehicle_type NVARCHAR(100) NOT NULL,    -- 'Reefer Van', 'Heavy Reefer Truck'
    capacity_kg DECIMAL(10,2) NOT NULL,
    status NVARCHAR(50) NOT NULL             -- 'ACTIVE', 'MAINTENANCE', 'DECOMMISSIONED'
);
GO

-- 5. Fact Table: Shipments
CREATE TABLE dbo.shipments (
    shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL FOREIGN KEY REFERENCES dbo.customers(customer_id),
    origin_warehouse_id INT NOT NULL FOREIGN KEY REFERENCES dbo.warehouses(warehouse_id),
    destination_city NVARCHAR(100) NOT NULL,
    vehicle_id INT NOT NULL FOREIGN KEY REFERENCES dbo.vehicles(vehicle_id),
    driver_id INT NOT NULL FOREIGN KEY REFERENCES dbo.drivers(driver_id),
    temp_zone NVARCHAR(50) NOT NULL,         -- 'DEEP_FREEZE' (-18C), 'CHILLED' (2C to 8C)
    temp_min_c FLOAT NOT NULL,
    temp_max_c FLOAT NOT NULL,
    scheduled_pickup DATETIME2 NOT NULL,
    actual_pickup DATETIME2 NULL,
    scheduled_delivery DATETIME2 NOT NULL,
    actual_delivery DATETIME2 NULL,
    status NVARCHAR(50) NOT NULL,            -- 'DELIVERED', 'IN_TRANSIT', 'CANCELLED'
    distance_km FLOAT NOT NULL,
    pallets INT NOT NULL,
    revenue_qar DECIMAL(12,2) NOT NULL,
    fuel_cost_qar DECIMAL(12,2) NOT NULL
);
GO

-- 6. Fact Table: Financial Invoices & Accounts Receivable
CREATE TABLE dbo.invoices (
    invoice_id INT IDENTITY(1,1) PRIMARY KEY,
    shipment_id INT NOT NULL FOREIGN KEY REFERENCES dbo.shipments(shipment_id),
    customer_id INT NOT NULL FOREIGN KEY REFERENCES dbo.customers(customer_id),
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount_qar DECIMAL(12,2) NOT NULL,
    paid_date DATE NULL                      -- NULL indicates outstanding unpaid receivable
);
GO

-- 7. Fact Table: Vehicle Maintenance Events
CREATE TABLE dbo.maintenance (
    maintenance_id INT IDENTITY(1,1) PRIMARY KEY,
    vehicle_id INT NOT NULL FOREIGN KEY REFERENCES dbo.vehicles(vehicle_id),
    maintenance_date DATE NOT NULL,
    cost_qar DECIMAL(12,2) NOT NULL,
    service_type NVARCHAR(100) NOT NULL,
    odometer_km INT NOT NULL
);
GO

-- 8. Fact Table: IoT Cold-Chain Telematics (High-Frequency Temperature Readings)
CREATE TABLE dbo.temp_readings (
    reading_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    shipment_id INT NOT NULL FOREIGN KEY REFERENCES dbo.shipments(shipment_id),
    reading_timestamp DATETIME2 NOT NULL,
    recorded_temp_c FLOAT NOT NULL,
    is_breached BIT NOT NULL DEFAULT 0
);
GO
