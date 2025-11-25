terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "local" {
    path = "../../../terraform-states/ci-cd-comparison/terraform-master/environment/terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.aws_role_arn
  }
}