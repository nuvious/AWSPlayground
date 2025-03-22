provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "primary_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_servicecatalogappregistry_application" "s3_playground" {
  name        = "S3Playground"
  description = "Application for managing S3 resources"
}

resource "aws_s3_bucket" "s3_playground_bucket" {
  bucket = "s3-playground-test"  # Ensure this bucket name is globally unique
  force_destroy = true

  tags = {
    "Environment" = "Development"
    "Application" = aws_servicecatalogappregistry_application.s3_playground.name
    "App" = aws_servicecatalogappregistry_application.s3_playground.name
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "all_outbound" {
  name        = "all_outbound"
  vpc_id      = aws_vpc.main.id

  tags = {
    "Environment" = "Development"
    "Application" = aws_servicecatalogappregistry_application.s3_playground.name
    "App" = aws_servicecatalogappregistry_application.s3_playground.name
  }
}

resource "aws_vpc_security_group_egress_rule" "example" {
  security_group_id = aws_security_group.all_outbound.id

  cidr_ipv4   = "0.0.0.0/0"
  to_port     = -1
}

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.public_a.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.web.id]

  attachment {
    instance     = aws_instance.test.id
    device_index = 1
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2_playground" {
  key_name      = aws_key_pair.example.key_name
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }

  user_data = <<-EOL
  #!/bin/bash
  echo 'ubuntu:ubuntu' | sudo chpasswd
  touch /home/ubuntu/setup_complete
  EOL

  tags = {
    Name = "Playground"
    "Environment" = "Development"
    "Application" = aws_servicecatalogappregistry_application.s3_playground.name
    "App" = aws_servicecatalogappregistry_application.s3_playground.name
  }
}
