terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "local" {
    path = "../../../terraform-states/ci-cd-comparison/terraform-master/github-org/terraform.tfstate"
  }
}


# Configure the GitHub Provider
provider "github" {
    owner = var.organization
}