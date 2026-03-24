#
# Security Groups Module
# Creates security groups for web servers, API servers, and databases
#

# Web Server Security Group
resource "aws_security_group" "web" {
  name        = var.web_sg_name
  description = var.web_sg_description
  vpc_id      = var.vpc_id
  tags = {
    Name = var.web_sg_name
  }

  # HTTP
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.web_sg_cidr]
  }

  # HTTPS
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.web_sg_cidr]
  }

  # SSH (restricted)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.web_sg_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# API Server Security Group
resource "aws_security_group" "api" {
  name        = var.api_sg_name
  description = var.api_sg_description
  vpc_id      = var.vpc_id
  tags = {
    Name = var.api_sg_name
  }

  # API Port (example: 8080)
  ingress {
    description = "API traffic from web servers"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    security_groups = [var.web_sg_id]
  }

  # SSH (restricted)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.api_sg_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = var.db_sg_name
  description = var.db_sg_description
  vpc_id      = var.vpc_id
  tags = {
    Name = var.db_sg_name
  }

  # MySQL port
  ingress {
    description = "MySQL from API servers"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [var.api_sg_id]
  }

  # PostgreSQL port (optional)
  # ingress {
  #   description = "PostgreSQL from API servers"
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   security_groups = [var.api_sg_id]
  # }

  # SSH (restricted)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.db_sg_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

outputs "web_sg_id" {
  value = aws_security_group.web.id
}

outputs "api_sg_id" {
  value = aws_security_group.api.id
}

outputs "db_sg_id" {
  value = aws_security_group.db.id
}
