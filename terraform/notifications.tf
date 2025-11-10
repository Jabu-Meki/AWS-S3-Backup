resource "aws_sns_topic" "backup_notifications" {
    name = "backup-notifications-topic"

    tags = {
        Name = "Backup Notifications"
        Environment = var.environment
        ManagedBy = "Terraform"
    }
}

resource "aws_sns_topic_subscription" "backup_email_subscription" {
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol = "email"
  endpoint = var.notification_email
}