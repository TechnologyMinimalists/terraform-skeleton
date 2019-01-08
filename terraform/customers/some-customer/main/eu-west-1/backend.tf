variable "workspace_iam_roles" {
  type = "map"

  default = {
    "staging"    = "arn:aws:iam::STAGING-ACCOUNT-ID:role/Terraform"
    "production" = "arn:aws:iam::PRODUCTION-ACCOUNT-ID:role/Terraform"
    "develop"    = "arn:aws:iam::DEV-ACCOUNT-ID:role/Terraform"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "${var.region}"

  #assume_role = "${var.workspace_iam_roles[terraform.workspace]}"
}

terraform {
  backend "s3" {
    bucket         = "some-tfstate-bucket"
    key            = "eu-central-1/main.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-dynamodb-lock-table"

    # role_arn = "arn:aws:iam::PRODUCTION-ACCOUNT-ID:role/Terraform"
  }
}


