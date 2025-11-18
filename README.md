# AWS S3 Automated Backup System

![Build & Test](https://github.com/Jabu-Meki/AWS-S3-Backup/actions/workflows/backup_pipeline.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20IAM%20%7C%20SNS-orange)
![Tech Stack](https://img.shields.io/badge/Stack-Bash%20%7C%20Python%20%7C%20Docker%20%7C%20Terraform-blue)

## Overview

A production-grade automated backup solution that demonstrates modern DevOps practices and cloud-native architecture. The system manages the complete backup lifecycle—from file compression and S3 upload to cost optimization, anomaly detection, and automated alerting.

Built with Infrastructure as Code principles, the entire AWS infrastructure is provisioned via Terraform, while Docker ensures consistent execution across environments. A secure CI/CD pipeline implements keyless authentication and automated deployments.

**Key Achievement:** Integrated statistical anomaly detection identifies unusual backup patterns (potential data corruption or security incidents) and automatically triggers alerts when backups deviate beyond 2 standard deviations from historical norms.

---

## Core Features

### Backup Automation
- **Intelligent File Management**: Automated compression, upload, and retention management
- **Smart Rotation**: Maintains the 5 most recent backups with automatic cleanup
- **Error Recovery**: Comprehensive pre-flight checks and graceful failure handling
- **Detailed Logging**: Timestamped operation logs with dedicated error tracking

### Infrastructure & Security
- **Infrastructure as Code**: Complete AWS resource provisioning via Terraform (S3, IAM, SNS)
- **IAM Role-Based Access**: Dedicated IAM roles for backup operations and cost analysis with least-privilege policies
- **Keyless Authentication**: OIDC-based IAM roles eliminate long-lived credentials in CI/CD
- **Container Isolation**: Separate Docker containers for backup and cost analysis ensure reproducible environments
- **Secure Credential Management**: AWS credentials mounted read-only in containers

### Cost Optimization
- **Automated Cost Analysis**: Python-based analyzer calculates storage costs across tiers
- **Lifecycle Policies**: Automatic transition to cheaper storage classes (Standard → IA → Glacier)
- **Historical Tracking**: CSV-based time-series data for trend analysis
- **Savings Reporting**: Detailed breakdowns of cost optimizations

### Monitoring & Intelligence
- **Real-time Notifications**: SNS alerts for backup success/failure with detailed metrics
- **Anomaly Detection**: Statistical analysis (mean, standard deviation) identifies unusual patterns
- **Automated Alerting**: High-priority notifications when backups exceed normal variance
- **Performance Metrics**: Tracks backup duration, file size, and success rates

### CI/CD Pipeline
- **Automated Testing**: Shellcheck linting and validation on every commit
- **Continuous Deployment**: Automated Docker image builds and registry pushes
- **Scheduled Execution**: Automated daily backups and weekly cost analysis
- **Version Control**: Automated commits of analysis reports back to repository

---

## Architecture

### System Flow

1. **Code Push** → GitHub triggers CI/CD pipeline
2. **Validation** → Automated linting and security checks
3. **Build** → Docker images built and pushed to registry
4. **Authentication** → OIDC provider issues temporary AWS credentials
5. **Execution** → Containerized jobs run backup and cost analysis
6. **Storage** → Compressed archives uploaded to S3
7. **Analysis** → Cost calculations and anomaly detection
8. **Notification** → SNS alerts sent based on results
9. **Commit** → Updated metrics committed to repository

### AWS Resources (Terraform-managed)

- **S3 Bucket**: Backup storage with versioning and lifecycle policies
- **IAM Roles**: 
  - Backup execution role with S3 write permissions
  - Cost analyzer role with S3 read permissions
  - OIDC provider trust relationship for GitHub Actions
- **SNS Topic**: Email/SMS notification delivery
- **OIDC Provider**: GitHub Actions authentication without long-lived keys

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Cloud Platform** | AWS (S3, IAM, SNS) |
| **Infrastructure** | Terraform 1.0+ |
| **Containerization** | Docker, Docker Compose |
| **CI/CD** | GitHub Actions |
| **Scripting** | Bash (backup logic) |
| **Analytics** | Python 3 (boto3, pandas, numpy) |
| **Version Control** | Git, GitHub |

---

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.0 or later
- Docker and Docker Compose
- Python 3.8+ with pip (for local development)
- Git

### Installation

#### 1. Clone and Configure
```bash
git clone https://github.com/Jabu-Meki/AWS-S3-Backup.git
cd AWS-S3-Backup
```

#### 2. Provision Infrastructure
```bash
cd terraform

# Update variables for your environment
# Edit terraform/variables.tf with your email and bucket name

terraform init
terraform plan
terraform apply
```

Note the output values:
- `bucket_name` - S3 bucket for backups
- `sns_topic_arn` - ARN for notifications
- `backup_role_arn` - IAM role ARN for backup operations
- `cost_analyzer_role_arn` - IAM role ARN for cost analysis

#### 3. Configure Environment
```bash
# Export required variables
export SNS_TOPIC_ARN="<from_terraform_output>"
export BUCKET_NAME="<from_terraform_output>"
```

### Usage

#### Run Backup

**Option 1: Docker Compose (Recommended)**
```bash
docker-compose run backup
```

**Option 2: Docker Run**
```bash
docker build -f docker/Dockerfile -t aws-s3-backup:latest .

docker run --rm \
  -v ~/.aws:/root/.aws:ro \
  -v "$(pwd)/backups":/data/source_files \
  -v "$(pwd)/logs":/app/logs \
  -e SNS_TOPIC_ARN="${SNS_TOPIC_ARN}" \
  aws-s3-backup:latest <bucket-name>
```

**Option 3: Direct Script Execution**
```bash
./backup.sh <bucket-name>
```

#### Run Cost Analysis

**Option 1: Docker (Recommended)**
```bash
docker build -f docker/cost.Dockerfile -t aws-cost-analyzer:latest .

docker run --rm \
  -v ~/.aws:/root/.aws:ro \
  -v "$(pwd)/reports":/app/reports \
  aws-cost-analyzer:latest <bucket-name> --save-csv /app/reports/cost_report.csv
```

**Option 2: Docker Compose**
```bash
docker-compose run cost-analyzer
```

**Option 3: Local Python Environment**
```bash
# Set up virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run analyzer
python3 python-tools/cost_analyzer.py <bucket-name> --save-csv reports/cost_report.csv
```

---

## CI/CD Setup

### GitHub Actions Configuration

The pipeline (`.github/workflows/backup_pipeline.yml`) automatically authenticates to AWS using IAM roles configured in Terraform.

#### Required Secrets

- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token

**Note**: AWS credentials are NOT stored in GitHub Secrets. Authentication uses OIDC with temporary credentials issued by the IAM role defined in `terraform/iam.tf`.

#### Optional Secrets

- `SLACK_WEBHOOK_URL` - Slack notification integration

#### IAM Role Configuration

The Terraform configuration creates:
- **Backup Role**: Permissions for S3 PutObject, GetObject, ListBucket operations
- **Cost Analyzer Role**: Permissions for S3 ListBucket, GetBucketSize operations
- **OIDC Trust Policy**: Allows GitHub Actions to assume these roles

Update `terraform/iam.tf` to match your repository:
```hcl
# Example trust policy
condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:sub"
  values   = ["repo:your-username/AWS-S3-Backup:*"]
}
```

### Pipeline Triggers

- **Push/PR**: Validation and build on every commit
- **Schedule**: Daily backups (2 AM UTC), weekly cost analysis (Sundays 3 AM UTC)
- **Manual**: On-demand execution via GitHub UI

---

## Cost Optimization

### Storage Lifecycle

| Age | Storage Class | Cost/GB/Month | Use Case |
|-----|--------------|---------------|----------|
| 0-29 days | Standard | $0.023 | Recent backups (frequent access) |
| 30-89 days | Standard-IA | $0.0125 | Older backups (infrequent access) |
| 90-364 days | Glacier | $0.004 | Archive (rare access) |
| 365+ days | Deleted | $0 | Automatic cleanup |

### Example Savings

**Scenario**: 100GB monthly backups

- Without lifecycle policies: **$2.30/month**
- With lifecycle policies: **~$0.85/month**
- **Annual savings**: $17.40 (63% reduction)

---

## Monitoring & Alerting

### Notification Types

**Success Notifications** include:
- Backup file name and size
- Upload duration
- Total backup count
- Timestamp

**Failure Notifications** include:
- Error description
- Failed operation
- Log file location
- Timestamp

**Anomaly Alerts** include:
- Current vs. expected backup size
- Standard deviation calculation
- Historical comparison
- Recommended actions

### Log Files

- `logs/backup.log` - All operations with timestamps
- `logs/backup-errors.log` - Error-specific entries
- `reports/cost_report.csv` - Historical cost data

---

## Anomaly Detection

The system uses statistical analysis to identify unusual backup patterns:

1. **Data Collection**: Each backup's size and duration are logged
2. **Baseline Calculation**: Mean and standard deviation computed from historical data
3. **Threshold Detection**: New backups compared against baseline (±2σ)
4. **Automated Alerting**: SNS notification sent when thresholds exceeded

**Use Cases**:
- Detect data corruption or incomplete backups
- Identify configuration changes
- Flag potential security incidents (ransomware, unauthorized access)

---

## Project Structure
```
AWS-S3-Backup/
├── .github/
│   └── workflows/
│       └── backup_pipeline.yml    # CI/CD configuration
├── docker/
│   ├── Dockerfile                 # Backup container definition
│   └── cost.Dockerfile            # Cost analyzer container definition
├── terraform/
│   ├── main.tf                    # Infrastructure definitions
│   ├── variables.tf               # Configuration variables
│   ├── iam.tf                     # IAM roles and policies
│   └── notifications.tf           # SNS configuration
├── python-tools/
│   └── cost_analyzer.py           # Cost analysis script
├── reports/                       # Generated cost reports
├── logs/                          # Application logs
├── backup.sh                      # Main backup script
├── docker-compose.yml             # Container orchestration
├── requirements.txt               # Python dependencies
└── README.md                      # This file
```

---

## Development Roadmap

### Completed Features
- [x] Core backup automation with rotation
- [x] Infrastructure as Code with Terraform
- [x] Docker containerization
- [x] CI/CD pipeline with GitHub Actions
- [x] SNS notifications
- [x] Cost analysis and tracking
- [x] Statistical anomaly detection
- [x] Keyless OIDC authentication

### Future Enhancements
- [ ] Differential/incremental backups
- [ ] Multi-region replication
- [ ] Web-based dashboard
- [ ] Enhanced ML models (time-series forecasting)
- [ ] Backup encryption at rest
- [ ] CloudWatch metrics integration

---

## Security Best Practices

- **No Hardcoded Credentials**: All secrets managed via environment variables or AWS IAM
- **Least Privilege IAM**: Roles scoped to minimum required permissions
- **Read-Only Mounts**: AWS credentials mounted as read-only in containers
- **Encrypted Transit**: All AWS API calls use TLS
- **State File Security**: Terraform state files excluded from version control
- **Dependency Scanning**: Automated vulnerability checks in CI/CD

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes with clear commit messages
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Author

**Jabu Meki**

- GitHub: [@Jabu-Meki](https://github.com/Jabu-Meki)
- LinkedIn: www.linkedin.com/in/jabulani-meki-cloudguy

---

## Acknowledgments

- AWS Documentation for S3 and IAM best practices
- HashiCorp for Terraform
- Docker community for containerization patterns
- GitHub Actions team for CI/CD capabilities

---

**Questions or suggestions?** Open an issue or reach out via LinkedIn.