#
# RDS Module
# Creates RDS database with high availability
#

resource "aws_db_instance" "instance" {
  allocated_storage                = var.allocated_storage
  storage_type                     = var.storage_type
  storage_encrypted                = var.storage_encrypted
  iops                             = var.iops
  db_instance_identifier           = var.db_instance_identifier
  db_instance_class                = var.db_instance_class
  engine                           = var.db_engine
  engine_version                   = var.db_version
  license_model                    = var.license_model
  master_username                  = var.master_username
  master_password                  = var.master_password
  db_name                          = var.db_name
  apply_immediately                = var.apply_immediately
  multi_az                         = var.multi_az
  backup_retention_period          = var.backup_retention_period
  backup_window                    = var.backup_window
  preferred_backup_window          = var.preferred_backup_window
  preferred_backup_window          = "06:00-06:59"
  vpc_security_group_ids           = var.vpc_security_group_ids
  db_subnet_group_name             = var.db_subnet_group_name
  publicly_accessible              = false
  auto_minor_version_upgrade       = true
  enable_performance_insights      = var.enable_performance_insights
  performance_insights_retention_period = var.performance_insights_retention_period
  enable_cloudwatch_logs_exports   = var.enable_cloudwatch_logs_exports
  monitoring_interval              = var.monitoring_interval
  enable_performance_insights      = var.enable_performance_insights
  skip_final_snapshot              = var.skip_final_snapshot
  final_snapshot_identifier        = var.final_snapshot_identifier
  tags = {
    Name        = var.db_instance_identifier
    Environment = var.environment
  }
}

output "endpoint" {
  value = aws_db_instance.instance.endpoint
}

output "db_instance_identifier" {
  value = aws_db_instance.instance.db_instance_identifier
}

output "db_instance_arn" {
  value = aws_db_instance.instance.db_instance_arn
}

output "db_instance_status" {
  value = aws_db_instance.instance.db_instance_status
}
