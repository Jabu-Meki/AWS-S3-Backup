# Terraform Infrastructure

## Overview
This directory contains Terraform configuration to provision AWS infrastructure for the backup system.

## Resources Created
- **S3 Bucket** - Storage for backups
- **Bucket Versioning** - Track file versions
- **Lifecycle Policies** - Automatic cost optimization
  - Day 30: Move to Infrequent Access (IA)
  - Day 90: Move to Glacier
  - Day 365: Delete

## Prerequisites
- Terraform installed (v1.0+)
- AWS CLI configured with credentials
- Appropriate IAM permissions for S3

## Usage

### Initialize Terraform
```bash
terraform init
```

### Preview Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

## Configuration

### Variables
Edit `variables.tf` to customize:
- `bucket_name` - S3 bucket name (must be globally unique)
- `aws_region` - AWS region
- `environment` - Environment tag

### Outputs
After `terraform apply`, you'll see:
- Bucket name
- Bucket ARN
- Bucket region

## File Structure
```
terraform/
├── main.tf           # Main infrastructure definitions
├── variables.tf      # Input variables
├── README.md         # This file
└── terraform.tfstate # State file (auto-generated)
```

## Cost Optimization
Lifecycle policies automatically reduce costs:
- **Standard Storage**: $0.023/GB/month
- **Infrequent Access**: $0.0125/GB/month (45% savings)
- **Glacier**: $0.004/GB/month (83% savings)

## Notes
- State file contains sensitive info - do not commit to public repos
- For production, use remote state (S3 + DynamoDB)