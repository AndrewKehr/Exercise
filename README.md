# Wiz Support Technical Exercise

This project demonstrates deploying a cloud infrastructure on AWS using Terraform, including:

* An EC2 instance running MongoDB with secure access via AWS SSM
* Automated MongoDB backups to an S3 bucket
* A containerized Go web app (Tasky) connecting to MongoDB
* Deployment of Tasky to an EKS cluster

---

## Contents

* [Architecture Overview](#architecture-overview)
* [Prerequisites](#prerequisites)
* [How to Deploy](#how-to-deploy)
* [MongoDB on EC2](#mongodb-on-ec2)
* [S3 Backups](#s3-backups)
* [Containerized Web App (Tasky)](#containerized-web-app-tasky)
* [Outputs](#outputs)

---

## Architecture Overview

* **Terraform-managed infrastructure**: VPC, subnets, security groups, EC2, S3, IAM roles, and EKS cluster
* **MongoDB** installed and configured securely on Amazon Linux 2 EC2
* **S3** bucket for storing database backups
* **Kubernetes** cluster (EKS) for hosting containerized applications

---

## Prerequisites

* AWS CLI configured (`aws configure`)
* Terraform v1.4+ installed
* Docker installed and configured
* MongoDB v4+ compatible clients (e.g., `mongosh`)
* GitHub Actions configured for CI/CD workflows
* AWS EC2 Key Pair named `wiz-keypair`

---

## How to Deploy

### 1. Clone and initialize Terraform

```bash
git clone <your-repo-url>
cd Exercise/terraform
terraform init
terraform apply -var="key_pair_name=wiz-keypair"
```

### 2. Connect to MongoDB EC2 via SSM

```bash
aws ssm start-session --target <instance-id>
```

---

## MongoDB on EC2

* Port: `27017` (bound to `localhost`)
* Admin credentials:

  * Username: `admin`
  * Password: `WizSecurePass123!`

### To connect:

```bash
mongosh -u admin -p 'WizSecurePass123!' --authenticationDatabase admin
```

---

## S3 Backups

Backups are automated using a cron job on the EC2 instance that runs the `dbbackup.sh` script.

### To run a manual backup:

```bash
sudo bash /opt/scripts/dbbackup.sh
```

Backups are uploaded to the provisioned S3 bucket. Filenames include timestamps for uniqueness.
[https://wiz-public-backups-78d7cf71.s3.amazonaws.com/](https://wiz-public-backups-78d7cf71.s3.amazonaws.com/)

---

## Containerized Web App (Tasky)

Tasky is containerized and deployed to EKS.
Access this deployment of Tasky here: [http://af97934a7008a49f9b2397a6295e3855-672729978.us-east-1.elb.amazonaws.com/](http://af97934a7008a49f9b2397a6295e3855-672729978.us-east-1.elb.amazonaws.com/)

### Steps:

1. Build Docker image and push to ECR
2. Apply Kubernetes manifests in `/tasky`
3. Access via an exposed LoadBalancer

---

## GitHub Actions CI/CD

This project uses GitHub Actions to automate the following workflows:

* Build Docker images for the Node.js app and Tasky
* Push images to Amazon Elastic Container Registry (ECR)
* Deploy the containerized apps to the EKS cluster using `kubectl`
* Optionally validate infrastructure using Terraform plan/apply

[![Build and Push to ECR](https://github.com/AndrewKehr/Exercise/actions/workflows/deploy.yml/badge.svg)](https://github.com/AndrewKehr/Exercise/actions/workflows/deploy.yml)
[![Terraform CI](https://github.com/AndrewKehr/Exercise/actions/workflows/terraform.yml/badge.svg)](https://github.com/AndrewKehr/Exercise/actions/workflows/terraform.yml)

### Workflow Highlights

* The GitHub Actions workflows are defined in `.github/workflows/`
* Secrets such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `ECR_REPOSITORY_URI` are securely stored in GitHub
* Each push to the `main` branch triggers:

  * Docker build & push for updated services
  * Kubernetes manifest deployment

---

## Outputs

After `terraform apply`, you will get:

* `ec2_public_ip`: Public IP of MongoDB EC2 (for initial setup only)
* `s3_bucket_name`: Name of S3 bucket used for backups
* `eks_cluster_name`: EKS cluster provisioned for app deployment
