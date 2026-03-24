#
# Security Groups Module Variables
#

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "web_sg_name" {
  description = "Name for web security group"
  type        = string
  default     = "web-sg"
}

variable "web_sg_description" {
  description = "Description for web security group"
  type        = string
  default     = "Security group for web servers"
}

variable "web_sg_cidr" {
  description = "CIDR for web security group (0.0.0.0/0 for public, private for internal)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "api_sg_name" {
  description = "Name for API security group"
  type        = string
  default     = "api-sg"
}

variable "api_sg_description" {
  description = "Description for API security group"
  type        = string
  default     = "Security group for API servers"
}

variable "api_sg_cidr" {
  description = "CIDR for API security group"
  type        = string
  default     = "10.0.0.0/16"
}

variable "api_port" {
  description = "API port (default: 8080)"
  type        = number
  default     = 8080
}

variable "db_sg_name" {
  description = "Name for database security group"
  type        = string
  default     = "db-sg"
}

variable "db_sg_description" {
  description = "Description for database security group"
  type        = string
  default     = "Security group for database servers"
}

variable "db_sg_cidr" {
  description = "CIDR for database security group"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_port" {
  description = "Database port (default: 3306 for MySQL)"
  type        = number
  default     = 3306
}

variable "web_sg_id" {
  description = "Web security group ID for referencing from API SG"
  type        = string
}

variable "api_sg_id" {
  description = "API security group ID for referencing from DB SG"
  type        = string
}
