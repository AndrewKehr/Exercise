#!/bin/bash

TIMESTAMP=$(date +"%F-%H-%M")
BACKUP_DIR="/tmp/mongo-backup-$TIMESTAMP"
ARCHIVE_FILE="/tmp/mongo-backup-$TIMESTAMP.tar.gz"
S3_BUCKET="wiz-public-backups-78d7cf71"

# MongoDB creds
MONGO_USER="admin"
MONGO_PASS="WizSecurePass123!"
AUTH_DB="admin"

# Dump the db
mongodump \
  --username="$MONGO_USER" \
  --password="$MONGO_PASS" \
  --authenticationDatabase="$AUTH_DB" \
  --out "$BACKUP_DIR" --username admin --password 'WizSecurePass123!' --authenticationDatabase admin

# Check if dump succeeded
if [ $? -ne 0 ]; then
  echo "MongoDB dump failed. Aborting backup."
  exit 1
fi

# Compress the backup
tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" .

# Upload to S3.  This bucket is hardcoded but this could be assigned dynamically with an env var, cli arg, or terraform metadata
aws s3 cp "/tmp/mongo-backup-$TIMESTAMP.tar.gz" "s3://$S3_BUCKET/mongo-backup-$TIMESTAMP.tar.gz"

# Clean up
rm -rf "$BACKUP_DIR" "$ARCHIVE_FILE"
