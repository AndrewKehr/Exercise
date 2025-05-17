#!/bin/bash

TIMESTAMP=$(date +"%F-%H-%M")
BACKUP_DIR="/tmp/mongo-backup-$TIMESTAMP"
ARCHIVE_FILE="/tmp/mongo-backup-$TIMESTAMP.tar.gz"
S3_BUCKET="wiz-public-backups-78d7cf71"

# MongoDB credentials
MONGO_USER="admin"
MONGO_PASS="WizSecurePass123!"
AUTH_DB="admin"

# Dump the database with authentication
mongodump \
  --username="$MONGO_USER" \
  --password="$MONGO_PASS" \
  --authenticationDatabase="$AUTH_DB" \
  --out "$BACKUP_DIR"

# Check if dump succeeded
if [ $? -ne 0 ]; then
  echo "MongoDB dump failed. Aborting backup."
  exit 1
fi

# Compress the backup
tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" .

# Upload to S3
aws s3 cp "$ARCHIVE_FILE" "s3://$S3_BUCKET/$(basename $ARCHIVE_FILE)" --acl public-read

# Clean up
rm -rf "$BACKUP_DIR" "$ARCHIVE_FILE"
