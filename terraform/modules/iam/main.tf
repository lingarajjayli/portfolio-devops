#
# IAM Module
# Creates IAM roles and policies for EC2 instances
#

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.iam_role_external_id
          }
        }
      }
    ]
  })

  tags = {
    Name        = var.iam_role_name
    Environment = var.environment
  }
}

# Attach managed policies
resource "aws_iam_policy_attachment" "s3_access" {
  name       = "s3-access"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "cloudwatch_access" {
  name       = "cloudwatch-access"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy_attachment" "cloudtrail_access" {
  name       = "cloudtrail-access"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudTrailReadAccess"
}

# IAM Policy for custom permissions
resource "aws_iam_policy" "custom_policy" {
  name   = var.iam_policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::devops-portfolio-static-assets/*",
          "arn:aws:s3:::devops-portfolio-static-assets"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:aws:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstances",
          "ssm:GetParameters",
          "ssm:SendCommand"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = var.iam_policy_name
    Environment = var.environment
  }
}

# Attach custom policy
resource "aws_iam_policy_attachment" "custom_policy_attachment" {
  name       = "custom-policy-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.custom_policy.arn
}

output "iam_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "iam_role_name" {
  value = aws_iam_role.ec2_role.name
}

output "iam_policy_arn" {
  value = aws_iam_policy.custom_policy.arn
}
