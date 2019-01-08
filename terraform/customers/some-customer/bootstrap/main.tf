# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "local" {
    path = "tfstate/terraform.local-tfstate"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "some-terraform-state-bucket"
  acl           = "private"
  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-dynamodb-lock-table"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}
