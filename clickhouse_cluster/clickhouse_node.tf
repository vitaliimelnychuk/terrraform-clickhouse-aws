data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



resource "aws_instance" "clickhouse" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_pair


  subnet_id       = var.subnet_id
  security_groups = var.security_groups

  tags = {
    Name = "${var.env}-${var.app}-${var.name}"
    App  = var.app
    Env  = var.env
  }
}


resource "aws_ebs_volume" "clickhouse" {
  availability_zone = "us-east-1a"
  size              = 500
  tags = {
    Name = "${var.env}-${var.app}-${var.name}-volume"
    App  = var.app
    Env  = var.env
  }
}

resource "aws_volume_attachment" "clickhouse" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.clickhouse.id
  instance_id = aws_instance.clickhouse.id
}
