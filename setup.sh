#!/bin/bash

set -euo pipefail

echo "Checking for required CLI tools"

for cmd in aws terraform kubectl; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it before running this script."
    exit 1
  fi
done

echo "CLI tools check passed."

echo "Running Terraform init & apply..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Waiting for EC2 MongoDB instance to be ready via SSM..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wiz-mongo-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo "Configuring MongoDB via SSM session..."
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Configure MongoDB" \
  --parameters commands="$(< mongo-init.sh)" \
  --region us-east-1 \
  --output text


echo "Setting up kubeconfig for EKS cluster..."
CLUSTER_NAME=$(terraform -chdir=terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --name "$CLUSTER_NAME"

echo "Building & deploying containerized app to EKS..."
kubectl apply -f k8s/deployment.yaml

echo "Granting cluster-admin to app service account..."
kubectl create clusterrolebinding wiz-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:default || true

echo "Setup complete!"
echo "Visit your app and MongoDB backups:"
echo "Web App URL: $(kubectl get svc wiz-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "S3 Backup URL: https://$(terraform -chdir=terraform output -raw s3_bucket_name).s3.amazonaws.com/"
