#
# EC2 Module Variables
#

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "availability_zone" {
  description = "Availability zone(s)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

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

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet ID for instances"
  type        = string
}

variable "web_volume_size" {
  description = "Web server volume size (GB)"
  type        = number
  default     = 50
}

variable "api_volume_size" {
  description = "API server volume size (GB)"
  type        = number
  default     = 100
}

variable "db_volume_size" {
  description = "Database server volume size (GB)"
  type        = number
  default     = 500
}

variable "image_version" {
  description = "Ubuntu Server version (22.04, 20.04)"
  type        = string
  default     = "22.04"
}

variable "keep_volumes" {
  description = "Whether to keep EBS volumes on destroy"
  type        = bool
  default     = false
}
