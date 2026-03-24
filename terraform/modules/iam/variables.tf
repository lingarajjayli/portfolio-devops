#
# IAM Module Variables
#

variable "iam_role_name" {
  description = "IAM role name for EC2 instances"
  type        = string
  default     = "devops-ec2-role"
}

variable "iam_role_external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = ""
}

variable "iam_policy_name" {
  description = "IAM policy name"
  type        = string
  default     = "devops-ec2-policy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
