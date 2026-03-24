#
# Terraform Configuration for DevOps Portfolio
# A realistic IaC demonstrating:
# - AWS VPC and networking setup
# - Security groups
# - EC2 instances
# - RDS databases
# - Auto-scaling groups
#

# Required providers
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = var.skip_credentials_validation
  skip_metadata_api_check     = var.skip_metadata_api_check
  skip_requesting_account_id  = var.skip_requesting_account_id

  # Assume role for cross-account access
  # assumed_role_duration = 3600
  # role_arn = "arn:aws:iam::123456789012:role/MyAssumedRole"
}

# Provider configuration for Google Cloud
provider "google" {
  project = var.google_project_id
  region  = var.google_region
}

# Local path module for local file operations
module "local_path" {
  source = "./modules/local-path"

  path = var.base_path
}

# VPC Module - Creates networking infrastructure
module "vpc" {
  source = "./modules/vpc"

  vpc_name        = var.vpc_name
  cidr            = var.vpc_cidr
  environment     = var.environment
  enable_nat_gateway = var.enable_nat_gateway
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id = module.vpc.vpc_id

  # Web server security group
  web_sg_name       = "web-server-sg"
  web_sg_description = "Security group for web servers"
  web_sg_cidr       = var.web_sg_cidr

  # API server security group
  api_sg_name       = "api-server-sg"
  api_sg_description = "Security group for API servers"
  api_sg_cidr       = var.api_sg_cidr

  # Database security group
  db_sg_name        = "database-sg"
  db_sg_description = "Security group for database servers"
  db_sg_cidr        = var.db_sg_cidr
}

# EC2 Instance Module
module "ec2" {
  source = "./modules/ec2"

  environment       = var.environment
  availability_zone = module.vpc.availability_zones

  # Web server instances
  web_instance_type = var.web_instance_type
  web_instance_count = var.web_instance_count
  web_key_name      = var.web_key_name

  # API server instances
  api_instance_type = var.api_instance_type
  api_instance_count = var.api_instance_count
  api_key_name       = var.api_key_name

  # Database instances
  db_instance_type = var.db_instance_type
  db_instance_count = var.db_instance_count
  db_key_name      = var.db_key_name

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids
  security_group_ids = [
    module.security_groups.web_sg_id,
    module.security_groups.api_sg_id,
    module.security_groups.db_sg_id
  ]
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment      = var.environment
  db_instance_class = var.db_instance_class
  db_engine        = var.db_engine
  db_version       = var.db_version
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = var.db_password

  vpc_id  = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.db_sg_id
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  ecr_name = var.ecr_name
  environment = var.environment

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  bucket_name = var.s3_bucket_name
  environment = var.environment
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  environment = var.environment
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"

  environment = var.environment
}

# Output values
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "db_endpoint" {
  value = module.rds.endpoint
}

output "web_ami" {
  value = module.ec2.web_ami_id
}

output "web_instance_ids" {
  value = module.ec2.web_instance_ids
}

output "web_instance_dns" {
  value = module.ec2.web_instance_dns
}

output "api_instance_ids" {
  value = module.ec2.api_instance_ids
}

output "api_instance_dns" {
  value = module.ec2.api_instance_dns
}

output "db_instance_id" {
  value = module.rds.db_instance_identifier
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}
