"""
GulfChill Logistics Pipeline - Automated Data Profiler & Quality Audit
Author: Ariaf Meddison (@ariafmeddison57-cmyk)
Description:
    Performs exploratory data analysis (EDA), null checks, duplicate
    detection, and schema verification for cold-chain logistics shipments.
"""

import sys
import pandas as pd
import numpy as np

def run_data_audit(file_path: str):
    print("=" * 70)
    print("GULFCHILL LOGISTICS - DATA QUALITY AUDIT REPORT")
    print("=" * 70)
    
    try:
        data = pd.read_csv(file_path)
    except Exception as e:
        print(f"Error loading CSV file: {e}")
        sys.exit(1)

    print(f"\n[+] Total Records Loaded: {data.shape[0]:,}")
    print(f"[+] Total Attributes:     {data.shape[1]}")
    print("\n--- Column Inventory ---")
    for idx, col in enumerate(data.columns, 1):
        print(f"  {idx:02d}. {col} ({data[col].dtype})")

    print("\n--- Summary Statistics (Numeric) ---")
    print(data.describe().round(2))

    print("\n--- Data Completeness & NULL Audit ---")
    null_counts = data.isnull().sum()
    null_pct = (null_counts / len(data)) * 100
    null_summary = pd.DataFrame({"Missing Values": null_counts, "Percentage (%)": null_pct})
    print(null_summary[null_summary["Missing Values"] > 0])

    print("\n--- Primary Key & Duplicate Audit ---")
    if "shipment_id" in data.columns:
        duplicate_shipments = data["shipment_id"].duplicated().sum()
        print(f"Duplicate shipment_id count: {duplicate_shipments}")
        if duplicate_shipments == 0:
            print("STATUS OK: Primary key integrity verified.")
        else:
            print(f"WARNING: Found {duplicate_shipments} duplicate primary keys!")

    print("\n" + "=" * 70)
    print("Audit Complete.")
    print("=" * 70)

if __name__ == "__main__":
    sample_path = r"C:\Users\USER\Desktop\gulfchill_shipments_practice.csv"
    run_data_audit(sample_path)
