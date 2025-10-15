terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.4"
    }
  }

  backend "local" {
    path = "../../../terraform-states/ci-cd-comparison/terraform-master/gitlab-org/terraform.tfstate"
  }
}


# Configure the GitLab Provider
provider "gitlab" {}