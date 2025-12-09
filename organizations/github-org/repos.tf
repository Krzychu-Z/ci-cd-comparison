resource "github_repository" "small-project" {
  name        = var.small_project.name
  description = var.small_project.description
  auto_init   = true
  delete_branch_on_merge = true
  visibility = "private"

  template {
    owner      = "Krzychu-Z" 
    repository = "MODBUS-CRC16-Golang"
    include_all_branches = true
  }
}

# resource "github_repository_ruleset" "small-project-pr-rules" {
#   name        = "Require PR to master"
#   repository  = github_repository.small-project.name
#   target      = "branch"
#   enforcement = "active"

#   conditions {
#     ref_name {
#       include = ["refs/heads/master"]
#       exclude = []
#     }
#   }

#   rules {
#     pull_request {
#       required_approving_review_count = 1
#       dismiss_stale_reviews_on_push   = true
#     }
#   }

#   depends_on = [ github_repository.small-project ]
# }

resource "github_repository" "large-project" {
  name        = var.large_project.name
  description = var.large_project.description
  auto_init   = true
  delete_branch_on_merge = true
  visibility = "private"

  template {
    owner      = "Krzychu-Z" 
    repository = "rust-compiler"
    include_all_branches = false
  }
}

resource "github_repository" "pipelines-repository" {
  name        = var.pipelines_repository.name
  description = var.pipelines_repository.description
  auto_init   = true
  delete_branch_on_merge = true
  visibility = "private"
}