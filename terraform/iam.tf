resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"

    client_id_list = [
        "sts.amazonaws.com"
    ]

    thumbprint_list = [ 
        "6938fd4d98bab03faadb97b34396831e3780aea1"
    ]

    tags = {
        Name = "GitHub Actions OIDC Provider"
    }
}

# Defining the IAM Role that the GitHub Actions workflow will assume
resource "aws_iam_role" "github_actions_role" {
    name = "GitHubActionsBackupRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Federated = aws_iam_openid_connect_provider.github.arn
                },
                Action = "sts:AssumeRoleWithWebIdentity",
                Condition = {
                    StringLike = {
                        "token.actions.githubusercontent.com:sub" : "repo:Jabu-Meki/AWS-S3-Backup:*"
                    }
                }
            }
        ]
    })

    tags = {
        Name = "Github Actions ROle for S3 Backup"
        ManagedBy = "Terraform"
    }
}

# Attaching the necessary policies to the IAM Role
resource "aws_iam_role_policy" "github_actions_policy" {
    name = "GithubActionsBackupPolicy"
    role = aws_iam_role.github_actions_role.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            # Permission to list all buckets
            {
                Effect = "Allow",
                Action = "s3:ListAllMyBuckets",
                Resource = "*"
            },
            # Permission to read, write, and delete objects in our specific backup bucket
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket",
                    "s3:GetObjectAttributes"
                ],
                Resource = [
                    aws_s3_bucket.backup_bucket.arn,
                    "${aws_s3_bucket.backup_bucket.arn}/*" # This covers all objects inside the bucket

                ]
            },
            # Permission to publish notifications to our specific SNS topic
            {
                Effect = "Allow",
                Action = "sns:Publish",
                Resource = aws_sns_topic.backup_notifications.arn
            }
        ]
    })
}

output "github_actions_role_arn" {
    description = "The ARN of the IAM Role for Github Actions"
    value = aws_iam_role.github_actions_role.arn
}