#!/bin/bash

set -euo pipefail

echo "Setting up MongoDB backup cron job"

# Get EC2 instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

COMMAND=$(cat <<'EOF' | base64
#!/bin/bash
(crontab -l 2>/dev/null; echo "*/30 * * * * /home/ec2-user/dbbackup.sh") | crontab -
EOF
)

# Send decoded command to EC2
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Add dbbackup.sh to cron" \
  --parameters "commands=[\"echo '$COMMAND' | base64 -d | bash\"]" \
  --output text

echo "Cron job successfully scheduled!"

aws ssm crontab -l