#
# Terraform Local Values
# Environment-specific configuration for DevOps Portfolio
#

# Environment Configuration
environment = "dev"

# AWS Configuration
aws_region = "us-east-1"
enable_nat_gateway = true

# VPC Configuration
vpc_name = "devops-portfolio-vpc"
vpc_cidr = "10.0.0.0/16"

# Security Group CIDRs
web_sg_cidr = "0.0.0.0/0"          # Allow all traffic to web servers
api_sg_cidr = "10.0.0.0/16"        # Internal only
db_sg_cidr  = "10.0.0.0/16"        # Internal only

# Instance Configuration
web_instance_type = "t3.medium"
web_instance_count = 2
web_key_name = "devops-key-pair"

api_instance_type = "t3.large"
api_instance_count = 2
api_key_name = "devops-key-pair"

db_instance_type = "r5.2xlarge"
db_instance_count = 1
db_key_name = "devops-key-pair"

# Database Configuration
db_instance_class = "db.r5.large"
db_engine = "mysql"
db_version = "8.0"
db_name = "appdb"
db_username = "admin"
db_password = "DevOps2026_Secure!@#Password123"

# ECR Configuration
ecr_name = "devops-portfolio-images"

# S3 Configuration
s3_bucket_name = "devops-portfolio-static-assets-dev"

# IAM Configuration
iam_role_name = "devops-ec2-role"
iam_policy_name = "devops-ec2-policy"

# EKS Configuration
eks_enabled = false  # Set to true for EKS-enabled setup
eks_version = "1.27"
eks_node_count = 2
eks_node_type = "t3.medium"

# Google Cloud Configuration (commented out if not using GCP)
# google_project_id = "devops-portfolio-project"
# google_region = "us-central1"
