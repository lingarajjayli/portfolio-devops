# Terraform Infrastructure as Code

This directory contains Terraform configurations for demonstrating Infrastructure as Code (IaC) best practices.

## Architecture Overview

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars    # Local values (gitignored in production)
├── README.md           # This file
└── modules/
    ├── vpc/            # VPC and networking module
    ├── security-groups/ # Security group module
    ├── ec2/            # EC2 instances module
    ├── rds/            # RDS database module
    ├── ecr/            # ECR repository module
    ├── s3/             # S3 bucket module
    ├── iam/            # IAM roles and policies
    └── lambda/         # Lambda functions module
```

## Key Features

### 1. VPC Infrastructure
- Private and public subnets
- NAT Gateway for private subnet access
- Internet Gateway
- Route tables

### 2. Security
- Multiple security groups (web, API, database)
- VPC flow logs
- Security best practices (least privilege)

### 3. Compute Resources
- Web server EC2 instances
- API server EC2 instances
- Database instances (RDS)
- Auto-scaling configuration

### 4. Storage
- S3 bucket for static assets
- EBS volumes for compute

### 5. Database
- MySQL RDS instance
- Automatic backups
- Multi-AZ deployment

### 6. Container Registry
- ECR repository for container images

### 7. Serverless
- Lambda functions for event-driven tasks

## Quick Start

### 1. Setup Credentials

```bash
# For AWS
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"

# For GCP
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan Infrastructure

```bash
terraform plan
```

### 4. Apply Infrastructure

```bash
terraform apply
```

### 5. Destroy Infrastructure

```bash
terraform destroy
```

## Module Documentation

### VPC Module

Creates a VPC with:
- Public and private subnets
- NAT Gateway
- Internet Gateway
- Route tables

### Security Groups Module

Creates security groups for:
- Web servers (HTTP/HTTPS, SSH)
- API servers (application ports)
- Database servers (database ports)

### EC2 Module

Provisions EC2 instances with:
- User data (scripts)
- EBS volumes
- Security group associations
- Key pairs

### RDS Module

Creates RDS database with:
- Automated backups
- Multi-AZ support
- Performance monitoring

### ECR Module

Creates ECR repository with:
- Image tagging
- Repository policies

### S3 Module

Creates S3 bucket with:
- Versioning
- Lifecycle policies
- CORS configuration

### IAM Module

Creates IAM roles and policies with:
- Least privilege principles
- Cross-account access (if configured)
- Resource-based policies

### Lambda Module

Creates Lambda functions with:
- VPC configuration
- Environment variables
- Event sources

## CI/CD Integration

The Terraform configuration can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Terraform Init
  run: terraform init

- name: Terraform Plan
  run: terraform plan

- name: Terraform Apply
  run: terraform apply -auto-approve
```

## Testing

Run tests for Terraform configurations:

```bash
# Run tfsec (security scanner)
tfsec terraform/

# Run tflint (linter)
tflint -c .tflint.rc

# Run terrascan (container security)
terrascan scan -r terraform/
```

## Monitoring

After deploying infrastructure:

1. **CloudWatch Logs**: Monitor application logs
2. **X-Ray**: Distributed tracing
3. **CloudTrail**: API activity logging
4. **SNS Alerts**: Customizable alerting

## Security Best Practices

1. **Secrets Management**: Use AWS Secrets Manager for sensitive data
2. **Key Rotation**: Implement key rotation policies
3. **Encryption**: Enable encryption at rest and in transit
4. **VPC Peering**: Secure cross-VPC communication
5. **Monitoring**: Enable CloudWatch and set up alarms

## License

MIT License
