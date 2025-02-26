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

  tags = {
    "Environment" = "Development"
    "Application" = aws_servicecatalogappregistry_application.s3_playground.name
    "App" = aws_servicecatalogappregistry_application.s3_playground.name
  }
}
