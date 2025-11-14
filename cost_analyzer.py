#!/usr/bin/env python3

import boto3
import argparse
import sys
import os
import json
import csv
from datetime import datetime, timezone
from botocore.exceptions import ClientError

# Official prices per GB for the us-east-1 region
PRICING = {
    "STANDARD": 0.023,
    "STANDARD_IA": 0.0125,
    "GLACIER": 0.004
}

def get_bucket_size(s3_client, bucket_name):
    """
    Calculate the total size and object count for a given S3 bucket.
    This function correctly handles buckets with more than 1000 objects using pagination.
    """

    print(f"\n[INFO] Calculating size for bucket: {bucket_name}...")
    total_size_bytes = 0
    object_count = 0

    try:
        paginator = s3_client.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=bucket_name)

        for page in pages:
            if "Contents" in page:
                for obj in page['Contents']:
                    total_size_bytes += obj['Size']
                    object_count += 1
        print(f"[SUCCESS] Calculation complete.")
        return total_size_bytes, object_count
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchBucket':
            print(f"\n[ERROR] The bucket '{bucket_name}' does not exist.")
        else:
            print(f"\n[ERROR] An AWS error occurred: {e}")

        sys.exit(1)

def generate_report_data(size_bytes, object_count, bucket_name):
    """
    Generate a report dictionary with size, object count, and estimated costs.
    """

    if size_bytes == 0:
        return {
            "bucket_name": bucket_name,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "total_objects": 0,
            "total_size_bytes": 0,
            "total_size_gb": 0.0,
            "costs": {
                "STANDARD": 0.0,
                "STANDARD_IA": 0.0,
                "GLACIER": 0.0
            },
            "savings": { "potential_savings_usd": 0.0, "potential_savings_percent": 0.0 },
            "message": "Bucket is empty."
        }
    
    # All calculations

    size_gb = size_bytes / (1024**3)  # 1024*1024*1024 bytes in a gigabyte
    standard_cost = size_gb * PRICING["STANDARD"]
    ia_cost = size_gb * PRICING["STANDARD_IA"]
    glacier_cost = size_gb * PRICING["GLACIER"]
    potential_savings = standard_cost - glacier_cost
    savings_percent = (potential_savings / standard_cost) * 100 if standard_cost > 0 else 0

    # Prepare report data

    return {
        "bucket_name": bucket_name,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "total_objects": object_count,
        "total_size_bytes": size_bytes,
        "total_size_gb": round(size_gb, 4),
        "costs": {
            "standard": round(standard_cost, 2),
            "infrequent_access": round(ia_cost, 2),
            "glacier": round(glacier_cost, 2)
        },
        "savings": {
            "potential_savings_usd": round(potential_savings, 2),
            "potential_savings_percent": round(savings_percent,2)
        }
    }

def print_report_to_console(report_data):
    """
    Print the report data to the console in a readable format.
    """

    print("\n--- S3 Bucket Analysis Report ---")
    print(f" Bucket:           {report_data['bucket_name']}")
    print(f" Timestamp (UTC):  {report_data['timestamp_utc']}")
    print(f" Total Objects:    {report_data['total_objects']}")
    print(f" Total Size:       {report_data['total_size_bytes']:,}")
    print(f" Total Size (GB):  {report_data['total_size_gb']:.4f} GB")
    print("------------------------------------------------") 

    # If the report has a speacial message (like empty bucket), print it and return
    if report_data.get("message"):
        print(f"\n[INFO] {report_data['message']}")
        return

   
    print("\n--- Estimated Monthly Costs (Simulation) ---")
    print(f"S3 Standard:          ${report_data['costs']['standard']:,.2f}")
    print(f"S3 Standard-IA:       ${report_data['costs']['infrequent_access']:,.2f}")
    print(f"S3 Glacier Flexible:  ${report_data['costs']['glacier']:,.2f}")
    print("---------------------------------------------")
    print("\n--- Potential Savings Analysis ---")
    print(f"Potential Savings:    ${report_data['savings']['potential_savings_usd']:,.2f}/month")
    print(f"Percentage Reduction: {report_data['savings']['potential_savings_percent']:.2f}%")
    print("----------------------------------")


def save_to_json(report_data, filename):

    try:
        with open(filename, 'w') as f:
            json.dump(report_data, f, indent=4)
        print(f"\n[SUCCESS] Report saved to JSON file: {filename}")

    except IOError as e:
        print(f"\n[ERROR] Failed to write JSON file: {filename}: {e}")
                                            

def save_to_csv(report_data, filename):

    file_exists = os.path.exists(filename)

    flat_data = {
        "bucket_name": report_data["bucket_name"],
        "timestamp_utc": report_data["timestamp_utc"],
        "total_objects": report_data["total_objects"],
        "total_size_bytes": report_data["total_size_bytes"],
        "total_size_gb": report_data["total_size_gb"],
        "cost_standard": report_data["costs"]["standard"],
        "cost_infrequent_access": report_data["costs"]["infrequent_access"],
        "cost_glacier": report_data["costs"]["glacier"],
        "potential_savings_usd": report_data["savings"]["potential_savings_usd"],
        "potential_savings_percent": report_data["savings"]["potential_savings_percent"]
    }

    try:
        with open(filename, 'a', newline='') as f:
            # We tell it what the column headers (fieldnames) should be.
            writer = csv.DictWriter(f, fieldnames=flat_data.keys())

            if not file_exists:
                writer.writeheader() # This writes the first row with the column names

            writer.writerow(flat_data)

            print(f"\n[SUCCESS] Report saved to CSV file: {filename}")
    except IOError as e:
        print(f"\n[ERROR] Failed to write to CSV file {filename}: {e}")


def main():
    # command-line argument parser
    parser = argparse.ArgumentParser(description="Analyze S3 bucket storage costs and generate reports.")

    parser.add_argument('bucket', help="The name of the S3 bucket to analyze.")
    parser.add_argument('--save-json', help="Save the full report to a JSON file. Provide a filename.")
    parser.add_argument('--save-csv', help="Save a summary report to a CSV file. Provide a filename.")
    args = parser.parse_args()

    print("--- AWS S3 Cost Analyzer Initialized ---")
    s3_client = boto3.client('s3')

    size_bytes, object_count = get_bucket_size(s3_client, args.bucket)
    report_data = generate_report_data(size_bytes, object_count, args.bucket)

    print_report_to_console(report_data)

    if args.save_json:
        save_to_json(report_data, args.save_json)

    if args.save_csv:
        save_to_csv(report_data, args.save_csv)

    print("\n--- Script Finished ---")

if __name__ == "__main__":
    main()