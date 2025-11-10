variable "aws_region" {
    description = "AWS region for resources"
    type = string
    default = "us-east-1"
}

variable "bucket_name" {
    description = "Name of the s3 backup bucket"
    type = string
    default = "terraform-backup-test-mjay-sys"
}

variable "environment" {
    description = "Environment name"
    type = string
    default = "Production"
}

variable "standard_ia_days" {
    description = "Days before transitioning to STANDARD_IA"
    type = number
    default = 30
}

variable "glacier_days" {
    description = "Days before transitioning to GLACIER"
    type = number
    default = 90
}

variable "expiration_days" {
    description = "Days before expiration"
    type = number
    default = 365
}

variable "notification_email" {
    description = "The email address to receive backup notifications"
    type = string
    default = "jabu24meki@gmail.com"
}