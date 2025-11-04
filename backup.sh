#!/bin/bash

BACKUP_DIR="/home/jabu/Documents/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"
NUM_FILES=10

LOG_FILE="/home/jabu/Documents/AWS-Projects/AWS-S3-Backup/backup.log"
ERROR_LOG="/home/jabu/Documents/AWS-Projects/AWS-S3-Backup/backup-errors.log"

log_message() {
   local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
   local message="$1"
   local log_entry="[${TIMESTAMP}] ${message}"
   
   echo "$log_entry"    # Print to console
   echo "$log_entry" >> "$LOG_FILE"  # Append to log file

}

log_error() {
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    local message="$1"
    local log_entry="[${TIMESTAMP}] ERROR: ${message}"
    
    echo "$log_entry"    # Print to console
    echo "$log_entry" >> $ERROR_LOG  # Append to error log file
    echo "$log_entry" >> $LOG_FILE  # Append to log file
}

log_message "Running pre-flight checks..."
# Checking if backup directory exists

# https://linuxize.com/post/bash-check-if-file-exists/
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "Backup directory ${BACKUP_DIR} does not exist. Creating it..."

    # Alternative:
    # mkdir -p "$BACKUP_DIR" || { log_error "Failed to create backup directory ${BACKUP_DIR}. Exiting."; exit 1;}
    
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        log_error "Failed to create backup directory ${BACKUP_DIR}. Exiting."
        exit 1
    fi
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



echo "Create new bucket? (Y/N)"
read input_option

if [ "$input_option" == "Y" ]; then
    echo "Enter new bucket name: "
    read bucket_name

    # Creating a bucket
    echo "Creating a new bucket..."
    aws s3 mb s3://$bucket_name
    if [ $? -ne 0 ]; then
        log_error "Failed to create bucket ${bucket_name}. Exiting."
        exit 1
    fi

    S3_BUCKET="s3://${bucket_name}"

    log_message "Created new bucket: ${bucket_name}"

else
    echo "Enter existing bucket name from the list: "
    aws s3 ls
    read bucket_name
    S3_BUCKET="s3://${bucket_name}"

    log_message "Backing up to an existing bucket: ${bucket_name}"
fi

echo "Creating test files in back up directory..."

log_message "Creating $NUM_FILES test files in $BACKUP_DIR"

for ((i=1; i<=$NUM_FILES; i++)); do
    #Create file name
    filename="$BACKUP_DIR/testfile_$i.txt"
    echo "This is test file number $i" > $filename
    echo "Created on $(date)" >> $filename
done
log_message "Created $NUM_FILES test files in ${BACKUP_DIR}"

tar -czf $BACKUP_FILE $BACKUP_DIR
log_message "Created compressed archive: ${BACKUP_FILE}"

aws s3 cp $BACKUP_FILE $S3_BUCKET/backups/
if [ $? -ne 0 ]; then
    log_error "Failed to upload ${BACKUP_FILE} to ${S3_BUCKET}/backups/. Exiting."
    exit 1
fi

log_message "Uploaded ${BACKUP_FILE} to ${S3_BUCKET}/backups/"


rm $BACKUP_FILE
log_message "Removed local backup file: ${BACKUP_FILE}"


BACKUP_FILE_COUNT=$(aws s3 ls $S3_BUCKET/backups/ 2>/dev/null | wc -l)

if [ $BACKUP_FILE_COUNT -gt 5 ]; then
    echo "Backup file count exceeds limit. Deleting oldest backup file..."
    log_message "Backup file count (${BACKUP_FILE_COUNT}) exceeds limit. Starting rotation."
    OLDEST_FILE=$(aws s3 ls $S3_BUCKET/backups/ 2>/dev/null | head -n 1 | awk '{print $4}')
    aws s3 rm $S3_BUCKET/backups/$OLDEST_FILE
    if [ $? -ne 0 ]; then
        log_error "Failed to delete oldest backup file ${OLDEST_FILE} from ${S3_BUCKET}/backups/. Exiting."
        exit 1
    fi

    log_message "Deleted oldest backup file: ${OLDEST_FILE}"
    


    echo "Deleted oldest backup file: $OLDEST_FILE"

else
    log_message "Backup file count (${BACKUP_FILE_COUNT}) within limit. No rotation needed."
fi

log_message "======================================================"
log_message "Backup script completed."
log_message "======================================================"