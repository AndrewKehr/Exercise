#!/bin/bash

set -euo pipefail

echo "Retrieving EC2 instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo "Encoding dbbackup.sh..."
ENCODED_SCRIPT=$(base64 -w 0 dbbackup.sh)

echo "Uploading dbbackup.sh to EC2 via SSM..."
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Upload dbbackup.sh" \
  --parameters "commands=[
    \"echo '$ENCODED_SCRIPT' | base64 -d > /home/ec2-user/dbbackup.sh\",
    \"chmod +x /home/ec2-user/dbbackup.sh\"
  ]" \
  --output text
