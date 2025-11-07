terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "cosmic_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cosmic_igw" {
  vpc_id = aws_vpc.cosmic_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "cosmic_public_subnet" {
  vpc_id                  = aws_vpc.cosmic_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table
resource "aws_route_table" "cosmic_public_rt" {
  vpc_id = aws_vpc.cosmic_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cosmic_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "cosmic_public_rta" {
  subnet_id      = aws_subnet.cosmic_public_subnet.id
  route_table_id = aws_route_table.cosmic_public_rt.id
}

# Security Group
resource "aws_security_group" "cosmic_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Cosmic MapleStory server"
  vpc_id      = aws_vpc.cosmic_vpc.id

  # SSH access (restrict to your IP for production)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # MapleStory Login Server
  ingress {
    description = "MapleStory Login Server"
    from_port   = 8484
    to_port     = 8484
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MapleStory Game Channels (7575-7577)
  ingress {
    description = "MapleStory Game Channels"
    from_port   = 7575
    to_port     = 7577
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MySQL (only if you need external access - not recommended)
  # ingress {
  #   description = "MySQL"
  #   from_port   = 3307
  #   to_port     = 3307
  #   protocol    = "tcp"
  #   cidr_blocks = var.allowed_ssh_cidr
  # }

  # Outbound internet access
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# Elastic IP
resource "aws_eip" "cosmic_eip" {
  domain   = "vpc"
  instance = aws_instance.cosmic_server.id

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.cosmic_igw]
}

# EC2 Instance
resource "aws_instance" "cosmic_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.cosmic_public_subnet.id
  vpc_security_group_ids = [aws_security_group.cosmic_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type          = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    db_password = var.db_password
  })

  tags = {
    Name = "${var.project_name}-server"
  }
}
