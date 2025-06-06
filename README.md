# Wiz Support Technical Exercise

This project demonstrates deploying a cloud infrastructure on AWS using Terraform, including:

* An EC2 instance running MongoDB with secure access via AWS SSM
* Automated MongoDB backups to an S3 bucket
* A containerized Go web app (Tasky), connecting to MongoDB
* Deployed Tasky application running on an EKS cluster


---

## Contents

* [Architecture Overview](#architecture-overview)
* [Architecture Diagram](#architecture-diagram)
* [Prerequisites](#prerequisites)
* [How to Deploy](#how-to-deploy)
* [MongoDB on EC2](#mongodb-on-ec2)
* [S3 Backups](#s3-backups)
* [Containerized Web App (Tasky)](#containerized-web-app-tasky)
* [Outputs](#outputs)
* [Teardown](#teardown)

---

## Architecture Overview

* **Terraform-managed infrastructure**: VPC, subnets, security groups, EC2, S3, IAM roles, and EKS cluster
* **MongoDB** installed and configured securely on Amazon Linux 2 EC2
* **S3** bucket for storing database backups
* **Kubernetes** cluster (EKS) for hosting containerized applications

## Architecture Diagram

![Architecture Diagram](./assets/Architecture.png)


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
terraform plan
terraform apply
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

*Note: The credentials provided are for demonstration purposes only.*

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
The Tasky app runs with cluster-admin privileges using a ClusterRoleBinding. This configuration is intentionally insecure and included for demonstration purposes only.  
Access this deployment of Tasky here: [http://af97934a7008a49f9b2397a6295e3855-672729978.us-east-1.elb.amazonaws.com/](http://af97934a7008a49f9b2397a6295e3855-672729978.us-east-1.elb.amazonaws.com/)

### Steps:

1. Build Docker image and push to ECR
2. Apply Kubernetes manifests in `/tasky`:
   - [deployment.yaml](./tasky/deployment.yaml)
   - [service.yaml](./tasky/service.yaml)
   - [clusterrolebinding.yaml](./tasky/clusterrolebinding.yaml)
3. Access via an exposed LoadBalancer endpoint

---

## GitHub Actions CI/CD

This project uses GitHub Actions to automate the following workflows:

* Build Docker images for Tasky
* Push images to ECR

[![Build and Push to ECR](https://github.com/AndrewKehr/Exercise/actions/workflows/deploy.yml/badge.svg)](https://github.com/AndrewKehr/Exercise/actions/workflows/deploy.yml)

### Workflow Highlights

* GitHub Actions workflows are defined in [.github/workflows/deploy.yml](./.github/workflows/deploy.yml)
* Secrets such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `ECR_REPOSITORY_URI` are securely stored in GitHub
* Automatic build and push of the Docker image to Amazon ECR

---

## Outputs

After `terraform apply`, you will get:

| Output Name       | Description                             |
|-------------------|-----------------------------------------|
| ec2_public_ip     | Public IP of MongoDB EC2 instance       |
| s3_bucket_name    | Name of the S3 bucket for backups       |
| eks_cluster_name  | EKS cluster used for Tasky deployment   |

---

## Teardown

To clean up all provisioned resources when you're finished:

```bash
cd Exercise/terraform
terraform destroy
```