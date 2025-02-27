# Define provider
provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

# Create the AWS App Registry Application
resource "aws_servicecatalogappregistry_application" "s3_playground" {
  name        = "S3Playground"
  description = "Application for managing S3 resources"
}

# Create an S3 Bucket
resource "aws_s3_bucket" "s3_playground_bucket" {
  bucket = "s3-playground-test"  # Ensure this bucket name is globally unique
  force_destroy = true

  tags = {
    "Environment" = "Development"
    "Application" = aws_servicecatalogappregistry_application.s3_playground.name
    "App" = aws_servicecatalogappregistry_application.s3_playground.name
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
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "Playground"
  }
}
