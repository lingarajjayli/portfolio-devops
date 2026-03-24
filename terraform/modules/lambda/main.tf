#
# Lambda Module
# Creates Lambda functions for event-driven tasks
#

# Lambda function for health check
resource "aws_lambda_function" "health_check" {
  function_name = "health-check"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = var.lambda_runtime

  filename = var.lambda_health_check_file

  environment {
    variables = {
      NODE_ENV   = var.lambda_env
      LOG_LEVEL  = var.lambda_log_level
      VERSION    = var.lambda_version
    }
  }

  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory
  publish               = var.lambda_publish
  vpc_config {
    security_group_ids = var.lambda_security_groups
    subnet_ids         = var.lambda_subnet_ids
    assign_public_ip   = var.lambda_public_ip
  }

  layers             = var.lambda_layers
  tracing_config {
    mode = "Active"
  }

  kms_key_id = var.lambda_kms_key_id

  tags = {
    Name        = var.lambda_health_check_name
    Environment = var.environment
  }
}

# Lambda function for data processing
resource "aws_lambda_function" "data_processor" {
  function_name = "data-processor"
  role          = var.lambda_role_arn
  handler       = "handler.processor"
  runtime       = var.lambda_runtime

  filename = var.lambda_data_processor_file

  environment {
    variables = {
      QUEUE_URL = var.lambda_queue_url
      REDIS_URL = var.lambda_redis_url
      API_URL   = var.lambda_api_url
    }
  }

  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory
  publish               = var.lambda_publish
  vpc_config {
    security_group_ids = var.lambda_security_groups
    subnet_ids         = var.lambda_subnet_ids
    assign_public_ip   = var.lambda_public_ip
  }

  layers             = var.lambda_layers
  tracing_config {
    mode = "Active"
  }

  kms_key_id = var.lambda_kms_key_id

  tags = {
    Name        = var.lambda_data_processor_name
    Environment = var.environment
  }
}

# Lambda function for scheduled tasks
resource "aws_lambda_function" "scheduled_task" {
  function_name = "scheduled-task"
  role          = var.lambda_role_arn
  handler       = "handler.scheduler"
  runtime       = var.lambda_runtime

  filename = var.lambda_scheduled_task_file

  environment {
    variables = {
      SCHEDULE        = var.lambda_schedule
      TOPIC_ARN       = var.lambda_topic_arn
      SQS_ARN         = var.lambda_sqs_arn
      SNS_ARN         = var.lambda_sns_arn
    }
  }

  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory
  publish               = var.lambda_publish
  vpc_config {
    security_group_ids = var.lambda_security_groups
    subnet_ids         = var.lambda_subnet_ids
    assign_public_ip   = var.lambda_public_ip
  }

  layers             = var.lambda_layers
  tracing_config {
    mode = "Active"
  }

  kms_key_id = var.lambda_kms_key_id

  tags = {
    Name        = var.lambda_scheduled_task_name
    Environment = var.environment
  }
}

# Event Source Mappings
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = var.sqs_event_source_arn
  function_name    = aws_lambda_function.health_check.function_name
  batching_config {
    maximum_batching_window_ms = var.batching_window_ms
    maximum_record_age_seconds = var.batching_max_record_age
  }
  function_response_types = var.function_response_types

  tags = {
    Name        = var.sqs_event_source_name
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "sns_mapping" {
  event_source_arn = var.sns_event_source_arn
  function_name    = aws_lambda_function.data_processor.function_name
  batch_size       = var.batch_size
  starting_position = var.starting_position

  tags = {
    Name        = var.sns_event_source_name
    Environment = var.environment
  }
}

output "health_check_arn" {
  value = aws_lambda_function.health_check.arn
}

output "data_processor_arn" {
  value = aws_lambda_function.data_processor.arn
}

output "scheduled_task_arn" {
  value = aws_lambda_function.scheduled_task.arn
}
