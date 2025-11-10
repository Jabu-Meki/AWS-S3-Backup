#!/bin/bash

BACKUP_DIR="/data/source_files"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"
NUM_FILES=10

LOG_FILE="/app/logs/backup.log"
ERROR_LOG="/app/logs/backup-errors.log"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN:-}"
START_TIME=$(date +%s)

log_message() {
   local TIMESTAMP message log_entry  # Declare all locals at the top
   TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
   message="$1"
   log_entry="[${TIMESTAMP}] ${message}"
   
   echo "$log_entry"
   echo "$log_entry" >> "$LOG_FILE"
}

log_error() {
    local TIMESTAMP message log_entry # Declare all locals at the top
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    message="$1"
    log_entry="[${TIMESTAMP}] ERROR: ${message}"
    
    echo "$log_entry"
    echo "$log_entry" >> "$ERROR_LOG"
    echo "$log_entry" >> "$LOG_FILE"
}

send_notification() {
    local subject="$1"
    local message="$2"

    if [ -z "$SNS_TOPIC_ARN" ]; then
        log_error "SNS_TOPIC_ARN not set. Skipping notification."
        return
    fi

    if aws sns publish --topic-arn "$SNS_TOPIC_ARN" --subject "$subject" --message "$message" >/dev/null 2>&1; then
        log_message "Notification sent successfully: $subject"
    else
        log_error "Failed to send SNS notification."
    fi

}

send_success_notification() {
    local backup_file="$1"
    local file_size="$2"
    local duration="$3"
    local subject="Backup Successful: ${S3_BUCKET}"
    local message

    message=$(cat <<EOF

      Backup Operation Successful!

    A new backup has been successfully uploaded to your S3 bucket.

Details:
- Bucket:         ${S3_BUCKET}
- Backup File:    ${backup_file}
- Compressed Size: ${file_size}
- Duration:       ${duration} seconds
- Timestamp:      $(date +"%Y-%m-%d %H:%M:%S %Z")

Status: All systems operational. No action required.
EOF
)


send_notification "$subject" "$message"


}

send_failure_notification() {
    local error_stage="$1"
    local subject=" Backup FAILED: ${S3_BUCKET}"
    local message

    message=$(cat <<EOF
CRITICAL ALERT: The backup operation has failed!

The automated backup script encountered a critical error and could not complete.

Error Details:
- Failed Stage:   ${error_stage}
- Bucket Target:  ${S3_BUCKET}
- Timestamp:      $(date +"%Y-%m-%d %H:%M:%S %Z")

Action Required: Please review the error logs immediately in 'backup-errors.log' to diagnose the issue.
EOF
)
    send_notification "$subject" "$message"
}


log_message "Running pre-flight checks..."
# Checking if backup directory exists

# https://linuxize.com/post/bash-check-if-file-exists/
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "Backup directory ${BACKUP_DIR} does not exist. Creating it..."

    mkdir -p "/app/logs"
    mkdir -p "$BACKUP_DIR" || { 
        log_error "Failed to create backup directory ${BACKUP_DIR}. Exiting."; 
        exit 1; 
    }

    log_message "Created backup directory: ${BACKUP_DIR}"
fi
# Checking if AWS CLI is installed
if  ! command -v aws &> /dev/null ; then
    log_error "AWS CLI is not installed. Please install it and configure your credentials. Exiting."
    exit 1

fi
# Checking if AWS CLI is configured
if  ! aws sts get-caller-identity &> /dev/null ; then
    log_error "AWS CLI is not configured properly. Please configure your credentials. Exiting."
    exit 1
fi

log_message "Pre-flight checks completed successfully."


log_message "==============================================="
log_message "Backup script started."
log_message "==============================================="



# Check if a bucket name is provided as the first argument ($1)
if [ -z "$1" ]; then
    log_error "No bucket name provided. This script must be run with a bucket name."
    log_error "Usage: ./backup.sh <your-s3-bucket-name>"
    exit 1
fi

S3_BUCKET="s3://$1"
log_message "Backing up to bucket: ${S3_BUCKET}"
    

echo "Creating test files in back up directory..."

log_message "Creating $NUM_FILES test files in $BACKUP_DIR"

for ((i=1; i<=NUM_FILES; i++)); do
    #Create file name
    filename="$BACKUP_DIR/testfile_$i.txt"
    echo "This is test file number $i" > $filename
    echo "Created on $(date)" >> $filename
done
log_message "Created $NUM_FILES test files in ${BACKUP_DIR}"

tar -czf "$BACKUP_FILE" "$BACKUP_DIR"
log_message "Created compressed archive: ${BACKUP_FILE}"

if ! aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/backups/"; then
    log_error "Failed to upload ${BACKUP_FILE} to ${S3_BUCKET}/backups/. Exiting."
    exit 1
fi
log_message "Uploaded ${BACKUP_FILE} to ${S3_BUCKET}/backups/"


rm "$BACKUP_FILE"
log_message "Removed local backup file: ${BACKUP_FILE}"


BACKUP_FILE_COUNT=$(aws s3 ls "$S3_BUCKET/backups/" 2>/dev/null | wc -l)

if [ "$BACKUP_FILE_COUNT" -gt 5 ]; then
    echo "Backup file count exceeds limit. Deleting oldest backup file..."
    log_message "Backup file count (${BACKUP_FILE_COUNT}) exceeds limit. Starting rotation."
    OLDEST_FILE=$(aws s3 ls "$S3_BUCKET/backups/" 2>/dev/null | head -n 1 | awk '{print $4}')


    if ! aws s3 rm "s3://${S3_BUCKET}/backups/${OLDEST_FILE}"; then
        log_error "Failed to delete oldest backup file ${OLDEST_FILE} from ${S3_BUCKET}/backups/. Exiting."
        exit 1
    fi


    log_message "Deleted oldest backup file: ${OLDEST_FILE}"
    


    echo "Deleted oldest backup file: $OLDEST_FILE"

else
    log_message "Backup file count (${BACKUP_FILE_COUNT}) within limit. No rotation needed."
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Use aws s3api head-object for a more efficient and reliable way to get file size
# The `|| echo 0` provides a fallback if the command fails
UPLOADED_SIZE=$(aws s3api head-object --bucket "$1" --key "backups/$BACKUP_FILE" --query "ContentLength" --output text 2>/dev/null || echo 0)

# Use awk for floating-point math to calculate MB
UPLOADED_SIZE_MB=$(awk "BEGIN {printf \"%.2fMB\", ${UPLOADED_SIZE}/(1024*1024)}")

log_message "Backup duration: ${DURATION} seconds."
log_message "Uploaded file size: ${UPLOADED_SIZE_MB}."

send_success_notification "$BACKUP_FILE" "$UPLOADED_SIZE_MB" "$DURATION"

log_message "======================================================"
log_message "Backup script completed."
log_message "======================================================"