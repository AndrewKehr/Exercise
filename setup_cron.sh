#!/bin/bash

set -euo pipefail

echo "Setting up MongoDB backup cron job on EC2..."

# Get EC2 instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

# Base64-encoded command block to safely inject multi-line shell
COMMAND=$(cat <<'EOF' | base64
#!/bin/bash
(crontab -l 2>/dev/null; echo "*/30 * * * * /home/ec2-user/dbbackup.sh") | crontab -
EOF
)

# Send decoded command to EC2 via SSM
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Add dbbackup.sh to cron" \
  --parameters "commands=[\"echo '$COMMAND' | base64 -d | bash\"]" \
  --output text

echo "Cron job successfully scheduled!"

aws ssm crontab -l