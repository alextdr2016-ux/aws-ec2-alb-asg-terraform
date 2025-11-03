# 🚀 AWS EC2 + ALB + Auto Scaling Group (Terraform Modular Project)

This project provisions a **scalable web infrastructure** on AWS using **Terraform modules**.  
It automatically deploys EC2 instances behind an Application Load Balancer, with Auto Scaling for high availability.

---

## 🏗️ Architecture Overview

Internet
│
▼
[ Application Load Balancer (ALB) ]
│
▼
[ Target Group ]───┬──▶ EC2 Instance 1 (Apache)
└──▶ EC2 Instance 2 (Apache)
▲
│
[ Auto Scaling Group (ASG) ]

**Key AWS Services used**

- EC2 (Amazon Linux 2023)
- Auto Scaling Group (ASG)
- Launch Template
- Application Load Balancer (ALB)
- Target Group + Health Checks
- Security Groups (ALB & EC2)
- Random ID for environment isolation

---

## 📁 Project Structure

aws-ec2-alb-asg-terraform/
├── modules/
│ └── app/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── user_data.sh
└── envs/
├── dev/
│ └── main.tf
├── stage/
│ └── main.tf
└── prod/
└── main.tf

- **modules/app** → main logic (EC2 + ALB + ASG)
- **envs/dev|stage|prod** → environment-specific configs
- **user_data.sh** → installs Apache and sets up a simple web page

---

## ⚙️ How to Deploy

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.6.0
- A valid key pair in AWS (`generalkeypair`)
- Network access to eu-north-1 (Stockholm)

### Commands

```bash
cd envs/dev

terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

alb_dns_name = "web-alb-xxxx.eu-north-1.elb.amazonaws.com"

🧹 Cleanup

When finished:

terraform destroy

🧠 Key Learning Points

Modular infrastructure design for AWS

Stateless deployments using Terraform

Load balancing and health checks

Auto scaling for fault tolerance

Clean separation between environments (dev, stage, prod)

🧩 Author

Alex Tudor
Cloud Engineer & Founder — Ejolie / Fabrex
📍 Romania | AWS Cloud | Terraform | DevOps

```
