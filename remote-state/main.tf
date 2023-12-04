provider "aws" {
  region = "ap-south-1"
}


# Create a S3 bucket to store remote state 
resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfstate-zivvy-${random_uuid.uuid.result}"
  force_destroy = true
}

resource "random_uuid" "uuid" {}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create a dynamodb 
# Required for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "app-state-zivvy"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}