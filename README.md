# Wiz Support Technical Exercise

This project demonstrates deploying a cloud infrastructure on AWS using Terraform, including:

* An EC2 instance running MongoDB with secure access via AWS SSM
* Automated MongoDB backups to an S3 bucket
* A containerized Node.js app connecting to MongoDB
* Deployment of the [2048 game](https://github.com/gabrielecirulli/2048) to an EKS cluster

---

## Contents

* [Architecture Overview](#architecture-overview)
* [Prerequisites](#prerequisites)
* [How to Deploy](#how-to-deploy)
* [MongoDB on EC2](#mongodb-on-ec2)
* [S3 Backups](#s3-backups)
* [Node.js Mongo App](#nodejs-mongo-app)
* [Containerized Web App](#containerized-web-app)
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

## Node.js Mongo App

A minimal Node.js app (`node-mongo-app`) was created to test the database connection.

### Environment variables:

* `MONGO_URI`: MongoDB connection string using admin credentials

### To build and run locally:

```bash
cd Exercise/node-mongo-app
docker build -t node-mongo-app .
docker run --rm -e MONGO_URI='mongodb://admin:WizSecurePass123!@<private-ip>:27017/admin' node-mongo-app
```

---

## Containerized Web App (2048 Game)

The [2048 game](https://github.com/gabrielecirulli/2048) is containerized and deployed to EKS.

### Steps:

1. Build Docker image and push to ECR
2. Apply Kubernetes manifests in `/k8s/deploy.yml`
3. Access via an exposed LoadBalancer

---

## GitHub Actions CI/CD

This project uses GitHub Actions to automate the following workflows:

* Build Docker images for the Node.js app and 2048 game
* Push images to Amazon Elastic Container Registry (ECR)
* Deploy the containerized apps to the EKS cluster using `kubectl`
* Optionally validate infrastructure using Terraform plan/apply

![CI](https://github.com/your-username/wiz-project/actions/workflows/deploy.yml/badge.svg)
![CI](https://github.com/your-username/wiz-project/actions/workflowsterraform.yml/badge.svg)

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