#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and fail on the first failure in a pipeline
set -euo pipefail

# Verify that required tools are installed
echo "Checking for required CLI tools"

for cmd in aws terraform kubectl; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it before running this script."
    exit 1
  fi
done

echo "CLI tools check passed."

# Initialize and apply Terraform to provision infrastructure
echo "Running Terraform init & apply..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Get the EC2 instance ID tagged with `wiz-mongo` for MongoDB setup
echo "Waiting for EC2 MongoDB instance to be ready via SSM..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

# Send a shell script to the EC2 instance via SSM to configure MongoDB
echo "Configuring MongoDB via SSM session..."
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Configure MongoDB" \
  --parameters commands="$(< mongo-init.sh)" \
  --region us-east-1 \
  --output text

# Configure kubectl to use the EKS cluster
echo "Setting up kubeconfig for EKS cluster..."
CLUSTER_NAME=$(terraform -chdir=terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --name "$CLUSTER_NAME"

# Deploy K8 resources to EKS
echo "Building & deploying containerized app to EKS..."
kubectl apply -f k8s/deployment.yaml

# Grant admin permissions to the default service account
echo "Granting cluster-admin to app service account..."
kubectl create clusterrolebinding wiz-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:default || true

#Final output with access instructions
echo "Setup complete!"
echo "Visit your app and MongoDB backups:"
echo "Web App URL: $(kubectl get svc wiz-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "S3 Backup URL: https://$(terraform -chdir=terraform output -raw s3_bucket_name).s3.amazonaws.com/"
