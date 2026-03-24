#
# Lambda Module Variables
#

variable "lambda_role_arn" {
  description = "ARN of the IAM role to use for Lambda execution"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime (e.g., nodejs18.x, python3.11)"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 512
}

variable "lambda_publish" {
  description = "Whether to publish Lambda layers"
  type        = bool
  default     = true
}

variable "lambda_public_ip" {
  description = "Whether to assign public IP to Lambda VPC"
  type        = bool
  default     = false
}

variable "lambda_security_groups" {
  description = "Security groups for Lambda VPC"
  type        = list(string)
  default     = []
}

variable "lambda_subnet_ids" {
  description = "Subnet IDs for Lambda VPC"
  type        = list(string)
  default     = []
}

variable "lambda_layers" {
  description = "Lambda layers ARNs"
  type        = list(string)
  default     = []
}

variable "lambda_kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = ""
}

variable "lambda_env" {
  description = "Lambda environment (development, staging, production)"
  type        = string
  default     = "development"
}

variable "lambda_log_level" {
  description = "Lambda log level"
  type        = string
  default     = "INFO"
}

variable "lambda_version" {
  description = "Lambda function version"
  type        = string
  default     = "1"
}

variable "lambda_health_check_name" {
  description = "Name for health check Lambda function"
  type        = string
  default     = "health-check"
}

variable "lambda_data_processor_name" {
  description = "Name for data processor Lambda function"
  type        = string
  default     = "data-processor"
}

variable "lambda_scheduled_task_name" {
  description = "Name for scheduled task Lambda function"
  type        = string
  default     = "scheduled-task"
}

variable "lambda_health_check_file" {
  description = "S3 path to Lambda handler for health check"
  type        = string
  default     = "health-check.zip"
}

variable "lambda_data_processor_file" {
  description = "S3 path to Lambda handler for data processor"
  type        = string
  default     = "data-processor.zip"
}

variable "lambda_scheduled_task_file" {
  description = "S3 path to Lambda handler for scheduled task"
  type        = string
  default     = "scheduled-task.zip"
}

variable "lambda_queue_url" {
  description = "URL for message queue (e.g., Redis, SQS)"
  type        = string
  default     = ""
}

variable "lambda_redis_url" {
  description = "Redis URL for Lambda functions"
  type        = string
  default     = ""
}

variable "lambda_api_url" {
  description = "API endpoint URL for Lambda functions"
  type        = string
  default     = ""
}

variable "lambda_schedule" {
  description = "Schedule for Lambda function (cron expression)"
  type        = string
  default     = ""
}

variable "lambda_topic_arn" {
  description = "SNS topic ARN for Lambda events"
  type        = string
  default     = ""
}

variable "lambda_sqs_arn" {
  description = "SQS queue ARN for Lambda events"
  type        = string
  default     = ""
}

variable "lambda_sns_arn" {
  description = "SNS ARN for Lambda events"
  type        = string
  default     = ""
}

variable "sqs_event_source_arn" {
  description = "SQS queue ARN for event source mapping"
  type        = string
  default     = ""
}

variable "sqs_event_source_name" {
  description = "Name for SQS event source mapping"
  type        = string
  default     = "sqs-event-source"
}

variable "sns_event_source_arn" {
  description = "SNS topic ARN for event source mapping"
  type        = string
  default     = ""
}

variable "sns_event_source_name" {
  description = "Name for SNS event source mapping"
  type        = string
  default     = "sns-event-source"
}

variable "batching_window_ms" {
  description = "Maximum batching window in milliseconds"
  type        = number
  default     = 500
}

variable "batching_max_record_age" {
  description = "Maximum record age in seconds for batching"
  type        = number
  default     = 5
}

variable "batch_size" {
  description = "Batch size for SNS event source"
  type        = number
  default     = 10
}

variable "starting_position" {
  description = "Starting position for SNS event source"
  type        = string
  default     = "LATEST"
}

variable "function_response_types" {
  description = "Function response types for SQS event source"
  type        = list(string)
  default     = ["Success", "BatchItemFailures"]
}
