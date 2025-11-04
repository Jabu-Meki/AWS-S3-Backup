#!/bin/bash


set -e 

BACKUP_DIR="/home/jabu/Documents/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"
NUM_FILES=10


echo "Create new bucket? (Y/N)"
read input_option

if [ "$input_option" == "Y" ]; then
    echo "Enter new bucket name: "
    read bucket_name

    # Creating a bucket
    echo "Creating a new bucket..."
    aws s3 mb s3://$bucket_name

    S3_BUCKET="s3://${bucket_name}"

else
    echo "Enter existing bucket name from the list: "
    aws s3 ls
    read bucket_name
    S3_BUCKET="s3://${bucket_name}"
fi

echo "Creating test files in back up directory..."

for ((i=1; i<=$NUM_FILES; i++)); do
    #Create file name
    filename="$BACKUP_DIR/testfile_$i.txt"
    echo "This is test file number $i" > $filename
    echo "Created on $(date)" >> $filename
done


tar -czf $BACKUP_FILE $BACKUP_DIR

aws s3 cp $BACKUP_FILE $S3_BUCKET/backups/
rm $BACKUP_FILE

# TODO: Print success message
echo "Uploaded $BACKUP_FILE to $S3_BUCKET/backups/ successfully."

BACKUP_FILE_COUNT=$(aws s3 ls $S3_BUCKET/backups/ | wc -l)

if [ $BACKUP_FILE_COUNT -gt 5 ]; then
    echo "Backup file count exceeds limit. Deleting oldest backup file..."
    OLDEST_FILE=$(aws s3 ls $S3_BUCKET/backups/ | head -n 1 | awk '{print $4}')
    aws s3 rm $S3_BUCKET/backups/$OLDEST_FILE
    echo "Deleted oldest backup file: $OLDEST_FILE"
fi