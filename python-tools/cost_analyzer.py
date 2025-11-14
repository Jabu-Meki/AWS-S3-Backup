#!/usr/bin/env python3

import boto3 # AWS SDK for Python
from datetime import datetime   # for timestamping logs

print("Starting cost analyzer...")
print("=" * 50)

bucket_name = "terraform-backup-test-mjay-sys"
print(f"Analyzing costs for bucket: {bucket_name}")

print("\n Connecting to AWS...")
s3_client = boto3.client('s3')
response = s3_client.list_buckets()

for bucket in response['Buckets']:
    print(f"  - {bucket['Name']}")


def get_bucket_size(bucket_name):
    """
    Calculate total size of a bucket in bytes.
    """

    print(f"\n Calculating size for bucket: {bucket_name}...")

    total_size = 0
    object_count = 0

    paginator = s3_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket_name)

    for page in pages:
        if "Contents" in page:
            for obj in page['Contents']:
                total_size += obj['Size'] # Add up sizes
                object_count += 1
    
    return total_size, object_count # Return multiple values!


size_bytes, num_objects = get_bucket_size(bucket_name)
size_gb = size_bytes / (1024 * 1024 * 1024)



print(f"\n Results:")
print(f"  Objects: {num_objects}")
print(f"  Total Size: {size_bytes:,} bytes")
print(f"  Total Size: {size_gb:.2f} GB")


def calculate_monthly_cost(size_gb):
    """
    Calculate estimated monthly cost based on size.
    Assuming a rate of $0.023 per GB for S3 Standard storage.
    """

    STANDARD_PRICE = 0.023 # per GB
    IA_PRICE = 0.0125 # per GB for Infrequent Access
    GLACIER_PRICE = 0.004 # per GB for Glacier storage

    standard_cost = size_gb * STANDARD_PRICE
    ia_cost = size_gb * IA_PRICE
    glacier_cost = size_gb * GLACIER_PRICE

    return {
        'standard': standard_cost,
        'infrequent_access': ia_cost,
        'glacier': glacier_cost
    }

costs = calculate_monthly_cost(size_gb)

print(f"\n Estimated Monthly Costs:")
print(f"   Current (Standard): ${costs['standard']:.2f}/month")
print(f"   Infrequent Access: ${costs['infrequent_access']:.2f}/month")
print(f"   Glacier: ${costs['glacier']:.2f}/month")

potential_savings = costs['standard'] - costs['glacier']
savings_percent = (potential_savings / costs['standard']) * 100


print(f"\n Potential Savings:")
print(f"   Switching to Glacier could save you: ${potential_savings:.2f}/month")
print(f"   That's a savings of: {savings_percent:.2f}%")


print("=" * 50)
print("Script completed.")