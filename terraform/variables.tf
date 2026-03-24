#
# Terraform Variables
# All configuration values for the DevOps Portfolio infrastructure
#

# AWS Configuration Variables
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "skip_credentials_validation" {
  description = "Skip AWS credentials validation (for local testing)"
  type        = bool
  default     = false
}

variable "skip_metadata_api_check" {
  description = "Skip AWS metadata API check"
  type        = bool
  default     = false
}

variable "skip_requesting_account_id" {
  description = "Skip requesting AWS account ID"
  type        = bool
  default     = false
}

# VPC Configuration Variables
variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "devops-portfolio-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# Security Group Configuration Variables
variable "web_sg_cidr" {
  description = "CIDR for web server security group"
  type        = string
  default     = "0.0.0.0/0"
}

variable "api_sg_cidr" {
  description = "CIDR for API server security group"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_sg_cidr" {
  description = "CIDR for database security group (internal only)"
  type        = string
  default     = "10.0.0.0/16"
}

# Instance Configuration Variables
variable "web_instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.medium"
}

variable "web_instance_count" {
  description = "Number of web server instances"
  type        = number
  default     = 2
}

variable "web_key_name" {
  description = "Key pair name for web servers"
  type        = string
  default     = "devops-key-pair"
}

variable "api_instance_type" {
  description = "EC2 instance type for API servers"
  type        = string
  default     = "t3.large"
}

variable "api_instance_count" {
  description = "Number of API server instances"
  type        = number
  default     = 2
}

variable "api_key_name" {
  description = "Key pair name for API servers"
  type        = string
  default     = "devops-key-pair"
}

variable "db_instance_type" {
  description = "EC2 instance type for database servers"
  type        = string
  default     = "r5.2xlarge"
}

variable "db_instance_count" {
  description = "Number of database server instances"
  type        = number
  default     = 1
}

variable "db_key_name" {
  description = "Key pair name for database servers"
  type        = string
  default     = "devops-key-pair"
}

# Database Configuration Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.large"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password (use secrets manager in production)"
  type        = string
  default     = "changeme_secure_password_123!"
}

# ECR Configuration Variables
variable "ecr_name" {
  description = "ECR repository name"
  type        = string
  default     = "devops-portfolio-images"
}

# S3 Configuration Variables
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "devops-portfolio-static-assets"
}

# IAM Configuration Variables
variable "iam_role_name" {
  description = "IAM role name for EC2 instances"
  type        = string
  default     = "devops-ec2-role"
}

variable "iam_policy_name" {
  description = "IAM policy name"
  type        = string
  default     = "devops-ec2-policy"
}

# EKS Configuration Variables
variable "eks_enabled" {
  description = "Whether to enable EKS cluster"
  type        = bool
  default     = false
}

variable "eks_version" {
  description = "Kubernetes EKS version"
  type        = string
  default     = "1.27"
}

variable "eks_node_count" {
  description = "Number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_type" {
  description = "EKS node type"
  type        = string
  default     = "t3.medium"
}

# Google Cloud Configuration Variables
variable "google_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "devops-portfolio-project"
}

variable "google_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
