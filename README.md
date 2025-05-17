# Wiz Support Technical Exercise

This project demonstrates deploying and configuring an EC2 instance running MongoDB using Terraform, with secure access via AWS SSM.

---

## Contents

* [Architecture Overview](#architecture-overview)
* [Prerequisites](#prerequisites)
* [How to Deploy](#how-to-deploy)
* [How to Connect to the EC2 Instance](#how-to-connect-to-the-ec2-instance)
* [MongoDB Details](#mongodb-details)
* [Outputs](#outputs)
* [Next Steps](#next-steps)

---

## Architecture Overview

* A single EC2 instance in a custom VPC, running Amazon Linux 2
* MongoDB installed and configured with authentication
* IAM roles and instance profiles allow secure access via SSM
* Public IP access allowed only for initial setup
* S3 bucket provisioned
* EKS cluster name reserved (not yet in use)

---

## Prerequisites

* AWS CLI with valid credentials configured (`aws configure`)
* Terraform v1.4+ installed
* An AWS EC2 Key Pair named `terraform-keypair`

---

## How to Deploy

```bash
git clone <this-repo>
cd terraform
terraform init
terraform apply -var="key_pair_name=terraform-keypair"
```

This will provision:

* EC2 instance
* IAM roles and instance profiles
* Security group
* MongoDB installation and config via cloud-init or setup script (next step)

---

## How to Connect to the EC2 Instance

```bash
aws ssm start-session --target <instance-id>
```

You can find the instance ID using:

```bash
aws ec2 describe-instances \
  --filters "Name=ip-address,Values=<public-ip>" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```

---

## MongoDB Details

* Installed on port `27017`
* Bound to `127.0.0.1` (localhost only)
* Admin user credentials:

  * **Username**: `admin`
  * **Password**: `WizSecurePass123!`
* To connect:

```bash
mongosh -u admin -p 'WizSecurePass123!' --authenticationDatabase admin
```

---

## Outputs

After `terraform apply`, you will get:

* `ec2_public_ip`: EC2 instance public IP
* `s3_bucket_name`: S3 bucket created
* `eks_cluster_name`: Reserved EKS cluster name (not yet deployed)

---

## Next Steps

* Automate MongoDB user setup and system config via `setup.sh`
* Remove public IP exposure and rely solely on SSM
* Optionally deploy a sample app using MongoDB
* (Optional) Use AWS Secrets Manager for MongoDB credentials
* (Optional) Upload to S3 and/or expand to EKS

---

## Author

Andrew Kehr

---
# Exercise
