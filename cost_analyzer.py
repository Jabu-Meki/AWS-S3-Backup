#!/usr/bin/env python3

import boto3
import argparse
import sys
import os
import json
import csv
import pandas as pd
import numpy as np
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

def send_anomaly_alert(current_size_gb, average_size_gb, threshold, bucket_name):
    """
    Send an alert when an anomaly is detected.
    """

    sns_client = boto3.client('sns')
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

    if not sns_topic_arn:
        print("[WARNING] SNS_TOPIC_ARN environment variable not set. Cannot send alert.")
        return
    subject = f"Anomaly Detected: Unusually Large Backup in {bucket_name}"
    message = f"""
    SECURITY & COST ALERT: A recent backup has been flagged as anomalous.

    The size of the latest backup is significantly larger than the historical average,
    exceeding the configured threshold. This may indicate a misconfiguration,
    runaway log files, or a potential security issue.

    Analysis:
    - Current Backup Size: {current_size_gb:.2f} GB
    - Historical Average Size: {average_size_gb:.2f} GB
    - Anomaly Threshold: {threshold:.2f} GB

    Action Required: Please investigate the source of the backup to determine the
    cause of this unusual increase in size.
    """

    try:
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        print(f"[SUCCESS] Anomaly alert sent successfully.")
    except ClientError as e:
        print(f"\n[ERROR] Failed to send anomaly alert via SNS: {e}")

def analyze_anomalies(csv_filename, current_report, bucket_name):
    """
    Analyze past reports in the CSV file to detect anomalies in cost changes.
    An anomaly is defined as a change greater than 50% compared to the average of past data.
    """

    print("\n-- Running Anomaly Detection --")
    try:
        # This script will use pandas to read the CSV and analyze past costs.
        df = pd.read_csv(csv_filename)

        if len(df) < 3:
            print("[INFO] Not enough historical data to perform anomaly analysis, need at least 3 data points")
            return
        
        # select all rows except the very last one
        historical_sizes = df['total_size_gb'].iloc[:-1]

        # Statistical calculations
        mean_size = historical_sizes.mean()
        std_dev = historical_sizes.std()

        # Define thresholds for anomaly detection
        anomaly_threshold = mean_size + (2 * std_dev)

        current_size = current_report['total_size_gb']

        print(f"Historical Average Size: {mean_size:.2f} GB")
        print(f"Standard Deviation: {std_dev:.2f} GB")
        print(f"Anomaly Threshold (>): {anomaly_threshold:.2f} GB")
        print(f"Current Backup Size: {current_size:.2f} GB")
        if current_size > anomaly_threshold:
            print(f"[ALERT] Anomaly detected! Current size {current_size:.2f} GB exceeds threshold.")
            send_anomaly_alert(current_size, mean_size, anomaly_threshold, bucket_name)
        else:
            print("[INFO] No anomalies detected in current backup size.")

    except FileNotFoundError:
        print(f"[INFO] History file not found. Skipping analysis on first run.")
    except Exception as e:
        print(f"[ERROR] An error occurred during anomaly detection: {e}")


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
        analyze_anomalies(args.save_csv, report_data, args.bucket)

    print("\n--- Script Finished ---")

if __name__ == "__main__":
    main()