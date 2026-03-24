#
# VPC Module
# Creates a VPC with public and private subnets, NAT Gateway, and internet access
#

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.vpc_name}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                    = var.subnet_count
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone        = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch  = true
  tags = {
    Name              = "${var.vpc_name}-public-subnet-${count.index}"
    Type              = "Public"
    Environment       = var.environment
    AvailabilityZone  = data.aws_availability_zones.available.names[count.index]
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count                    = var.subnet_count
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 100)
  availability_zone        = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch  = false
  tags = {
    Name              = "${var.vpc_name}-private-subnet-${count.index}"
    Type              = "Private"
    Environment       = var.environment
    AvailabilityZone  = data.aws_availability_zones.available.names[count.index]
  }
}

# Availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
}

# Main route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-main-route-table"
  }
}

resource "aws_route" "main_internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Public subnet route tables
resource "aws_route_table" "public" {
  count = var.subnet_count
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-public-route-table-${count.index}"
  }
}

resource "aws_route" "public_internet" {
  count               = var.subnet_count
  route_table_id      = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id           = aws_internet_gateway.igw.id
}

# Private subnet route tables with NAT Gateway
resource "aws_route_table" "private" {
  count = var.subnet_count
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-private-route-table-${count.index}"
  }
}

resource "aws_route" "private_nat" {
  count             = var.subnet_count
  route_table_id    = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id   = aws_nat_gateway.nat.id
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id        = aws_vpc.vpc.id
  traffic_type  = "ALL"
  logGroupName  = "vpc-flow-logs"
  logDeliveryLogsTo = null # Consider enabling for VPC flow log forwarding to CloudWatch

  lifecycle {
    ignore_changes = [logGroupName]
  }
}

outputs "vpc_id" {
  value = aws_vpc.vpc.id
}

outputs "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

outputs "subnet_ids" {
  value = aws_subnet.public[*].id
}

outputs "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

outputs "availability_zones" {
  value = data.aws_availability_zones.available.names
}
