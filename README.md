# AWS S3 Automated Backup System

![Shell](https://img.shields.io/badge/Shell-100%25-green)
![AWS](https://img.shields.io/badge/AWS-S3-orange)
![Status](https://img.shields.io/badge/Status-Active-success)

## 📋 Overview

This is a production-ready bash script that automates the backup process for local files to AWS S3. It features intelligent backup rotation, comprehensive logging, and robust error handling - built to run reliably in production environments.

**Key Problem It Solves:** Manual backups are unreliable and time-consuming. This script ensures your data is consistently backed up to S3 with automatic cleanup of old backups to manage storage costs.

## ✨ Features

- 🔄 **Automated Backup Rotation** - Maintains only the last 5 backups, automatically deleting older ones
- 📦 **Smart Compression** - Uses tar.gz to minimize upload size and costs
- 📝 **Comprehensive Logging** - Tracks every operation with timestamps for audit trails
- ⚠️ **Error Handling** - Pre-flight checks and graceful failure handling
- 🪣 **Flexible Bucket Management** - Create new buckets or use existing ones interactively
- 🔒 **AWS CLI Integration** - Validates credentials before attempting operations

## 🛠️ Technologies Used

- **Bash** - Shell scripting for automation
- **AWS CLI** - Interface with AWS S3
- **AWS S3** - Cloud object storage
- **tar/gzip** - File compression

## 📁 Project Structure
```
AWS-S3-Backup/
├── backup.sh           # Main backup automation script
├── backup.log          # Operational log with timestamps
├── backup-errors.log   # Dedicated error log
└── README.md          # Project documentation
```

## 🚀 Prerequisites

Before running this script, ensure you have:

- ✅ AWS Account with S3 access
- ✅ AWS CLI installed ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- ✅ AWS CLI configured with credentials (`aws configure`)
- ✅ Bash shell (Linux/macOS/WSL)
- ✅ Appropriate IAM permissions for S3 operations

## ⚙️ Installation
```bash
# 1. Clone the repository
git clone https://github.com/Jabu-Meki/AWS-S3-Backup.git
cd AWS-S3-Backup

# 2. Make the script executable
chmod +x backup.sh

# 3. Configure your backup directory (optional)
# Edit BACKUP_DIR variable in backup.sh if needed
```

## 💻 Usage
```bash
# Run the backup script
./backup.sh
```

**Interactive Prompts:**
1. Choose to create a new S3 bucket or use existing
2. Script handles the rest automatically!

**Example Output:**
```
[2025-10-27 16:30:45] Running pre-flight checks...
[2025-10-27 16:30:45] Pre-flight checks completed successfully.
[2025-10-27 16:30:45] ===============================================
[2025-10-27 16:30:45] Backup script started.
[2025-10-27 16:30:45] ===============================================
Create new bucket? (Y/N)
```

## 📊 How It Works

1. **Pre-flight Checks** - Validates backup directory, AWS CLI installation, and credentials
2. **Bucket Selection** - Interactive choice to create new or use existing S3 bucket
3. **File Generation** - Creates test files (configurable for production use)
4. **Compression** - Archives files using tar.gz with timestamp
5. **Upload to S3** - Securely transfers backup to designated S3 bucket
6. **Smart Rotation** - Counts existing backups and removes oldest if exceeding 5
7. **Cleanup & Logging** - Removes local archive and logs all operations

## 🔍 Logging

**Log Locations:**
- Main log: `./backup.log`
- Error log: `./backup-errors.log`

**What's Logged:**
- All operations with timestamps
- Pre-flight check results
- Bucket creation/selection
- File operations
- Upload status
- Rotation decisions
- Errors and failures

**Viewing Logs:**
```bash
# View main log
cat backup.log

# View only errors
cat backup-errors.log

# Search for specific date
grep "2025-10-27" backup.log

# Watch logs in real-time
tail -f backup.log
```

## 🚧 Project Status & Roadmap

### ✅ Completed
- [x] Phase 1: Basic backup functionality
- [x] Phase 2: Intelligent backup rotation
- [x] Phase 4: Production-grade logging and error handling

### 🎯 In Progress
- [ ] Phase 5: Infrastructure as Code with Terraform
- [ ] Phase 6: Docker containerization
- [ ] Phase 7: CI/CD pipeline with GitHub Actions
- [ ] Phase 8: S3 lifecycle policies for cost optimization

### 🔮 Future Enhancements
- Email/SNS notifications on backup completion/failure
- Multi-directory backup support
- Differential/incremental backups
- Backup encryption at rest
- Cost analysis dashboard
- Cron job automation guide

## 🎓 Learning Journey

This project evolved from a simple backup script to a production-ready automation tool. Each phase taught valuable DevOps skills:
- Bash scripting best practices
- AWS S3 operations and optimization
- Error handling and logging patterns
- Production readiness considerations

**Next Steps:** Expanding into Infrastructure as Code (Terraform), containerization (Docker), and full CI/CD automation.

## 📝 License

MIT License - feel free to use and modify for your needs

## 👤 Author

**Jabu Meki**
- GitHub: [@Jabu-Meki](https://github.com/Jabu-Meki)
- LinkedIn: www.linkedin.com/in/jabulani-meki-cloudguy

## 🙏 Acknowledgments

- AWS Documentation for S3 best practices
- The open-source community for bash scripting resources
- [Linuxize](https://linuxize.com/) for bash tutorials

---

**⭐ If you find this project helpful, please consider giving it a star!**
