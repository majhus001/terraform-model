provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.project_name}-${terraform.workspace}"
  acl    = "private"

  tags = {
    Environment = terraform.workspace
    Project     = var.project_name
  }
}
