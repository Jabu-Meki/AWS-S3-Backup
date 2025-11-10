output "bucket_name" {
    description = "The name of the S3 backup bucket"
    value = aws_s3_bucket.backup_bucket.id
}

output "bucket_arn" {
    description = "ARN of the S3 backup bucket"
    value = aws_s3_bucket.backup_bucket.arn
}

output "lifecycle_enabled" {
    description = "Lifecycle policy status"
    value = "Enabled - 30d->STANDARD_IA, 90d->GLACIER, Expire after 365d"
}

