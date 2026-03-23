terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
}
// "this" is a best practice since a name is provided later by var.bucket_name
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  force_destroy = var.persistent

  tags = {
    Name = var.bucket_name
  }
}


resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}