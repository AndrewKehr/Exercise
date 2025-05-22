#!/bin/bash

set -euo pipefail

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo "Sending SSM command to configure MongoDB"

aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Configure MongoDB" \
  --parameters '{"commands":["#!/bin/bash", "sudo systemctl restart mongod", "mongosh --eval \"use admin; db.createUser({ user: \\\"admin\\\", pwd: \\\"WizSecurePass123!\\\", roles: [{ role: \\\"root\\\", db: \\\"admin\\\" }] });\""]}' \
  --output text