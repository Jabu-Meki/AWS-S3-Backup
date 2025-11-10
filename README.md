# AWS S3 Automated Backup System

![Shell](https://img.shields.io/badge/Shell-100%25-green)
![AWS](https://img.shields.io/badge/AWS-S3-orange)
![Docker](https://img.shields.io/badge/Docker-Enabled-blue)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)
![Status](https://img.shields.io/badge/Status-Production-success)

## 📋 Overview

A production-ready, containerized backup automation system that leverages AWS S3 for reliable cloud storage. Built with bash scripting, Infrastructure as Code (Terraform), and Docker containerization, this system automates the entire backup lifecycle while optimizing costs through intelligent storage tiering.

**Key Problem Solved:** Manual backups are unreliable, time-consuming, and prone to human error. This system ensures automated, consistent backups with zero manual intervention, automatic cleanup, and cost optimization through AWS S3 lifecycle policies.

## ✨ Features

### Core Functionality
- 🔄 **Automated Backup Rotation** - Maintains only the last 5 backups, automatically deleting older ones
- 📦 **Smart Compression** - Uses tar.gz to minimize upload size and reduce costs
- 📝 **Comprehensive Logging** - Tracks every operation with timestamps for full audit trails
- ⚠️ **Robust Error Handling** - Pre-flight checks and graceful failure handling
- 🪣 **Flexible Bucket Management** - Create new buckets or use existing ones
- 🔒 **AWS CLI Integration** - Validates credentials before attempting operations

### Infrastructure & Deployment
- 🏗️ **Infrastructure as Code** - Complete Terraform configuration for reproducible infrastructure
- 💰 **Cost Optimization** - Automated lifecycle policies (Standard → IA → Glacier → Delete)
- 🐳 **Docker Containerized** - Runs consistently across any environment
- 🔄 **CI/CD Ready** - GitHub Actions pipeline for automated builds and deployments
- 📊 **Production Logging** - Separate error logs for easy troubleshooting

## 🛠️ Technologies Used

- **Bash** - Shell scripting for automation logic
- **AWS CLI** - Interface with AWS S3 services
- **AWS S3** - Cloud object storage with lifecycle policies
- **Terraform** - Infrastructure as Code for AWS resource provisioning
- **Docker** - Containerization for portability and consistency
- **GitHub Actions** - CI/CD pipeline automation
- **tar/gzip** - File compression

## 📁 Project Structure
```
AWS-S3-Backup/
├── backup.sh                 # Main backup automation script
├── docker/
│   └── Dockerfile           # Container definition
├── docker-compose.yml        # Easy Docker orchestration
├── terraform/
│   ├── main.tf              # Infrastructure definitions
│   ├── variables.tf         # Configurable variables
│   └── README.md            # Terraform documentation
├── .github/
│   └── workflows/
│       └── backup-pipeline.yml  # CI/CD automation
├── backups/                  # Local backup staging (gitignored)
├── logs/                     # Application logs (gitignored)
│   ├── backup.log
│   └── backup-errors.log
├── .gitignore
└── README.md                 # This file
```

## 🚀 Prerequisites

- ✅ AWS Account with S3 access
- ✅ AWS CLI installed and configured ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- ✅ Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- ✅ Terraform installed (v1.0+) - Optional for infrastructure management
- ✅ Appropriate IAM permissions for S3 operations

## ⚙️ Installation

### Option 1: Using Docker (Recommended)
```bash
# 1. Clone the repository
git clone https://github.com/Jabu-Meki/AWS-S3-Backup.git
cd AWS-S3-Backup

# 2. Build the Docker image
docker-compose build

# 3. Run backup
docker-compose run backup
```

### Option 2: Direct Script Execution
```bash
# 1. Clone the repository
git clone https://github.com/Jabu-Meki/AWS-S3-Backup.git
cd AWS-S3-Backup

# 2. Make script executable
chmod +x backup.sh

# 3. Run with bucket name
./backup.sh your-bucket-name
```

### Option 3: Provision Infrastructure with Terraform
```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Initialize Terraform
terraform init

# 3. Review planned changes
terraform plan

# 4. Apply infrastructure
terraform apply
```

## 💻 Usage

### Docker (Recommended)
```bash
# Run backup with docker-compose
docker-compose run backup

# Or with docker run
docker run --rm \
  -v ~/.aws:/root/.aws:ro \
  -v "$(pwd)/backups":/data/source_files \
  -v "$(pwd)/logs":/app/logs \
  aws-s3-backup:v1.0 \
  your-bucket-name
```

### Direct Script
```bash
./backup.sh your-bucket-name
```

### Example Output
```
[2025-11-07 00:47:25] Running pre-flight checks...
[2025-11-07 00:47:27] Pre-flight checks completed successfully.
[2025-11-07 00:47:27] ===============================================
[2025-11-07 00:47:27] Backup script started.
[2025-11-07 00:47:27] ===============================================
[2025-11-07 00:47:27] Backing up to bucket: s3://your-bucket-name
Creating test files in back up directory...
[2025-11-07 00:47:27] Creating 10 test files in /data/source_files
[2025-11-07 00:47:27] Created 10 test files in /data/source_files
[2025-11-07 00:47:27] Created compressed archive: backup-2025-11-07_00-47-25.tar.gz
[2025-11-07 00:47:30] Uploaded backup-2025-11-07_00-47-25.tar.gz to s3://your-bucket-name/backups/
[2025-11-07 00:47:30] Removed local backup file: backup-2025-11-07_00-47-25.tar.gz
[2025-11-07 00:47:33] Backup file count (2) within limit. No rotation needed.
[2025-11-07 00:47:33] ======================================================
[2025-11-07 00:47:33] Backup script completed.
[2025-11-07 00:47:33] ======================================================
```

## 📊 How It Works

### Backup Workflow

1. **Pre-flight Checks**
   - Validates backup directory exists (creates if missing)
   - Verifies AWS CLI installation
   - Confirms AWS credentials are configured

2. **Bucket Selection**
   - Uses bucket name provided as argument
   - Non-interactive mode for automation/containers

3. **File Generation**
   - Creates test files (configurable for production use)
   - Timestamps each file for tracking

4. **Compression**
   - Archives files using tar.gz with timestamp
   - Format: `backup-YYYY-MM-DD_HH-MM-SS.tar.gz`

5. **Upload to S3**
   - Securely transfers backup to designated S3 bucket
   - Validates upload success

6. **Smart Rotation**
   - Counts existing backups in S3
   - If more than 5 backups exist, deletes the oldest
   - Maintains exactly 5 most recent backups

7. **Cleanup & Logging**
   - Removes local compressed archive
   - Logs all operations with timestamps
   - Separate error log for troubleshooting

### Infrastructure Automation (Terraform)

The Terraform configuration provisions:
- S3 bucket with versioning enabled
- Lifecycle policies for cost optimization:
  - **Day 0-29**: Standard storage
  - **Day 30-89**: Infrequent Access (IA) - 45% cost savings
  - **Day 90-364**: Glacier storage - 83% cost savings
  - **Day 365+**: Automatic deletion

## 🔍 Logging

### Log Locations

**In Container:**
- Main log: `/app/logs/backup.log`
- Error log: `/app/logs/backup-errors.log`

**On Host (mounted):**
- Main log: `./logs/backup.log`
- Error log: `./logs/backup-errors.log`

### What's Logged

- All operations with timestamps
- Pre-flight check results
- Bucket selection
- File operations (creation, compression, upload)
- Upload status and file sizes
- Rotation decisions (kept/deleted backups)
- Errors and failures with detailed context

### Viewing Logs
```bash
# View main log
cat logs/backup.log

# View only errors
cat logs/backup-errors.log

# Search for specific date
grep "2025-11-07" logs/backup.log

# Count total successful backups
grep "Backup script completed" logs/backup.log | wc -l

# Watch logs in real-time
tail -f logs/backup.log
```

## 💰 Cost Optimization

### Storage Class Transitions

| Days | Storage Class | Cost/GB/Month | Savings vs Standard |
|------|--------------|---------------|---------------------|
| 0-29 | Standard | $0.023 | Baseline |
| 30-89 | Infrequent Access | $0.0125 | 45% |
| 90-364 | Glacier | $0.004 | 83% |
| 365+ | Deleted | $0 | 100% |

### Example Cost Calculation

**Scenario:** 100GB of backups per month

- **Without lifecycle policies:** $2.30/month
- **With lifecycle policies:** ~$0.80/month
- **Monthly savings:** $1.50 (65% reduction)
- **Annual savings:** $18.00

*Actual savings depend on backup frequency and retention needs*

## 🚧 Project Status & Roadmap

### ✅ Completed (MVP)

- [x] Phase 1: Basic backup functionality
- [x] Phase 2: Intelligent backup rotation
- [x] Phase 4: Production-grade logging and error handling
- [x] Phase 5: Infrastructure as Code with Terraform
- [x] Phase 6: Docker containerization
- [x] Phase 7: CI/CD pipeline with GitHub Actions

### 🔮 Planned Enhancements

- [ ] **Phase 8: Monitoring & Notifications**
  - AWS SNS email/SMS alerts
  - Slack/Discord webhook integration
  - CloudWatch metrics and dashboards
  - Real-time status notifications

- [ ] **Phase 9: Cost Analytics Dashboard**
  - Real-time cost tracking
  - Storage class breakdown
  - Month-over-month comparisons
  - Projected costs and optimization recommendations

- [ ] **Phase 10: Intelligent Backup Optimization**
  - Differential/incremental backups
  - Data deduplication
  - Compression optimization
  - Smart retention policies based on usage patterns

- [ ] **Phase 11: ML-Powered Anomaly Detection** 🤖
  - Unusual backup size detection
  - Upload time anomaly identification
  - Storage need predictions
  - Automated alerting on suspicious patterns
  - Pattern-based retention adjustments

## 🔒 Security Best Practices

- AWS credentials mounted read-only in containers (`:ro`)
- State files excluded from version control
- IAM roles with least-privilege access
- Encrypted data in transit (AWS CLI default)
- No hardcoded credentials in code

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - feel free to use and modify for your needs

## 👤 Author

**Jabu Meki**
- GitHub: [@Jabu-Meki](https://github.com/Jabu-Meki)
- LinkedIn: www.linkedin.com/in/jabulani-meki-cloudguy

## 🙏 Acknowledgments

- AWS Documentation for S3 best practices and lifecycle policies
- HashiCorp for Terraform
- Docker community for containerization patterns
- The open-source community for bash scripting resources

---

## 📚 Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**⭐ If you find this project helpful, please consider giving it a star!**

**💬 Questions? Open an issue or reach out on LinkedIn!**