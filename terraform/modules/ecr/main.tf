#
# ECR Module
# Creates ECR repository for container images
#

resource "aws_ecr_repository" "repository" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  lifecycle_policy {
    rule {
      tag_status        = "untagged"
      include_latest    = true
      expiration_days   = var.image_retention_days
      description       = "Automatically delete untagged images older than ${var.image_retention_days} days"
      predicate {
        type    = "tag"
        value   = "latest"
      }
    }
  }
  tags = {
    Name        = var.ecr_name
    Environment = var.environment
  }
}

# ECR repository policy
resource "aws_ecr_repository_policy" "repository_policy" {
  repository = aws_ecr_repository.repository.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowPullAndPushFromAllUsers"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetRepositoryPolicy",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Condition = [
          {
            Test     = "Bool"
            Variable = "aws:SecureTransport"
            Values   = ["true"]
          }
        ]
      }
    ]
  })
}

output "repository_url" {
  value = "https://${aws_ecr_repository.repository.repository_url}"
}
