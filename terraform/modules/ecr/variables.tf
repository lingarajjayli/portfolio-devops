#
# ECR Module Variables
#

variable "ecr_name" {
  description = "ECR repository name"
  type        = string
  default     = "devops-portfolio-images"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "image_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 30
}
