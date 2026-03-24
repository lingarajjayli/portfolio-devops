#
# EC2 Module
# Provisions EC2 instances for web, API, and database servers
#

# Web Server User Data
data "template_file" "web_userdata" {
  template = file("../userdata/web.sh")
}

# API Server User Data
data "template_file" "api_userdata" {
  template = file("../userdata/api.sh")
}

# Database Server User Data
data "template_file" "db_userdata" {
  template = file("../userdata/db.sh")
}

# Web Server Instances
resource "aws_instance" "web" {
  count                  = var.web_instance_count
  ami                    = data.aws_ami.ubuntu.latest_id
  instance_type          = var.web_instance_type
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  key_name               = var.web_key_name
  associate_public_ip_address = true

  user_data = data.template_file.web_userdata.rendered

  tags = {
    Name        = "${var.environment}-web-server-${count.index}"
    Environment = var.environment
    Type        = "WebServer"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# API Server Instances
resource "aws_instance" "api" {
  count                  = var.api_instance_count
  ami                    = data.aws_ami.ubuntu.latest_id
  instance_type          = var.api_instance_type
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  key_name               = var.api_key_name
  associate_public_ip_address = false

  user_data = data.template_file.api_userdata.rendered

  tags = {
    Name        = "${var.environment}-api-server-${count.index}"
    Environment = var.environment
    Type        = "APIServer"
  }
}

# Database Server Instance
resource "aws_instance" "db" {
  count                  = var.db_instance_count
  ami                    = data.aws_ami.ubuntu.latest_id
  instance_type          = var.db_instance_type
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  key_name               = var.db_key_name
  associate_public_ip_address = false

  user_data = data.template_file.db_userdata.rendered

  tags = {
    Name        = "${var.environment}-db-server-${count.index}"
    Environment = var.environment
    Type        = "DatabaseServer"
  }
}

# EBS Volumes for Web Servers
resource "aws_ebs_volume" "web" {
  count = var.web_instance_count
  availability_zone = element(aws_subnet.public[*].availability_zone, count.index)
  device_name       = element(concat(aws_subnet.public[*].availability_zone, var.web_instance_count), count.index)
  size              = var.web_volume_size
  type              = "gp3"

  tags = {
    Name = "${var.environment}-web-volume-${count.index}"
  }

  lifecycle {
    delete = var.keep_volumes
  }
}

# EBS Volumes for API Servers
resource "aws_ebs_volume" "api" {
  count = var.api_instance_count
  availability_zone = element(aws_subnet.public[*].availability_zone, count.index)
  device_name       = element(concat(aws_subnet.public[*].availability_zone, var.api_instance_count), count.index)
  size              = var.api_volume_size
  type              = "gp3"

  tags = {
    Name = "${var.environment}-api-volume-${count.index}"
  }

  lifecycle {
    delete = var.keep_volumes
  }
}

# EBS Volumes for Database
resource "aws_ebs_volume" "db" {
  count = var.db_instance_count
  availability_zone = element(aws_subnet.private[*].availability_zone, count.index)
  device_name       = element(concat(aws_subnet.private[*].availability_zone, var.db_instance_count), count.index)
  size              = var.db_volume_size
  type              = "gp3"

  tags = {
    Name = "${var.environment}-db-volume-${count.index}"
  }

  lifecycle {
    delete = var.keep_volumes
  }
}

# Get Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-server-${var.image_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

outputs "web_instance_ids" {
  value = aws_instance.web[*].id
}

outputs "web_instance_dns" {
  value = aws_instance.web[*].public_ip
}

outputs "api_instance_ids" {
  value = aws_instance.api[*].id
}

outputs "api_instance_dns" {
  value = aws_instance.api[*].private_ip
}

outputs "db_instance_ids" {
  value = aws_instance.db[*].id
}

outputs "db_instance_ips" {
  value = aws_instance.db[*].private_ip
}

outputs "web_ami" {
  value = data.aws_ami.ubuntu.id
}
