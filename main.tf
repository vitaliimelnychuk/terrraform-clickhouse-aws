terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.14.4"
}

provider "aws" {
  region = "us-east-1"
}


# Create AWS keypair and store public key in the root directory
resource "tls_private_key" "clickhouse_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "clickhouse_kp" {
  key_name   = "${var.app}_clickhouse_key"
  public_key = tls_private_key.clickhouse_pk.public_key_openssh

  provisioner "local-exec" {
    command = <<EOT
      echo '${tls_private_key.clickhouse_pk.private_key_pem}' > ./clickhouse.pem
      chmod 400 ./clickhouse.pem
    EOT

  }
}


# NETWORK
resource "aws_vpc" "main" {
  cidr_block           = "172.19.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app}-vpc-main"
  }
}

resource "aws_subnet" "public" {
  cidr_block              = aws_vpc.main.cidr_block
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.app}-subnet-public"
  }
}

# IGW for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app}-gateway-main"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "subnet_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route.internet_access.route_table_id
}

resource "aws_security_group" "ssh_access" {
  name        = "demo_clickhouse_ssh_access"
  description = "Allow connection to Clickhouse through 22 port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH connection"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TODO: whitelist only specific IP's
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "clickhouse_internet_access" {
  name        = "demo_clikhouse_main"
  description = "Allow connection to Clickhouse from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow Clickhouse server connection"
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Clickhouse server connection"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 clickhouse instance
module "clickhouse_cluster" {
  source          = "./clickhouse_cluster"
  key_pair        = aws_key_pair.clickhouse_kp.key_name
  name            = "clickhouse"
  app             = var.app
  env             = "dev"
  security_groups = [aws_security_group.ssh_access.id, aws_security_group.clickhouse_internet_access.id]
  subnet_id       = aws_subnet.public.id
  private_key     = tls_private_key.clickhouse_pk.private_key_pem
}
