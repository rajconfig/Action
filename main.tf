############################
# Ubuntu Latest AMI
############################

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# VPC
############################

resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr

  enable_dns_hostnames = true

  enable_dns_support   = true

  tags = {
    Name = "terraform-vpc"
  }
}

############################
# Public Subnet
############################

resource "aws_subnet" "public" {

  vpc_id                  = aws_vpc.main.id

  cidr_block              = var.public_subnet_cidr

  map_public_ip_on_launch = true

  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "public-subnet"
  }
}

############################
# Internet Gateway
############################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

############################
# Route Table
############################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

############################
# Route Association
############################

resource "aws_route_table_association" "public" {

  subnet_id = aws_subnet.public.id

  route_table_id = aws_route_table.public.id
}

############################
# Security Group
############################

resource "aws_security_group" "ec2_sg" {

  name = "ec2-security-group"

  vpc_id = aws_vpc.main.id

  ingress {

    description = "SSH"

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "HTTP"

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

############################
# EC2 Instance
############################

resource "aws_instance" "ubuntu" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  key_name = var.key_name

  associate_public_ip_address = true

  tags = {
    Name = "Ubuntu-EC2"
  }
}
