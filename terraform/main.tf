terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

resource "aws_s3_bucket" "backup_bucket" {
    bucket = var.bucket_name

    tags = {
        Name = "Backup Bucket"
        Environment = var.environment
        ManagedBy = "Terraform"
    }
}

resource "aws_s3_bucket_versioning" "backup_versioning" {
    bucket = aws_s3_bucket.backup_bucket.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_lifecycle" {
  bucket = aws_s3_bucket.backup_bucket.id

    rule {
        id = "archive-old-backups"
        status = "Enabled"

        filter {
            prefix = "backups/"
        }

        # Move backups older than 30 days to Infrequent Access (cheaper)
        transition {
            days = var.standard_ia_days
            storage_class = "STANDARD_IA"
        }

        # Move backups older than 90 days to Glacier (even cheaper)
        transition {
            days = var.glacier_days
            storage_class = "GLACIER"
        }

        # Delete backup older than 365 days
        expiration {
            days = var.expiration_days
        }
    }

}

output "sns_topic_arn" {
    description = "ARN of the SNS topic for backup notifications"
    value = aws_sns_topic.backup_notifications.arn
}