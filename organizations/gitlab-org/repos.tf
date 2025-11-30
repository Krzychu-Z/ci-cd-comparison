# --- small-project (import from GitHub template) ---
resource "gitlab_project" "small_project" {
  name                             = var.small_project.name
  description                      = var.small_project.description
  namespace_id                     = data.gitlab_group.parent.id
  visibility_level                 = "private"
  remove_source_branch_after_merge = true
  default_branch                   = "master"

  # NOTE: do NOT set initialize_with_readme when using import_url
  import_url = "https://github.com/Krzychu-Z/MODBUS-CRC16-Golang.git"
}

resource "gitlab_branch_protection" "small_master" {
  project            = gitlab_project.small_project.id
  branch             = "master"
}

# --- large-project (import from GitHub template) ---
resource "gitlab_project" "large_project" {
  name                             = var.large_project.name
  description                      = var.large_project.description
  namespace_id                     = data.gitlab_group.parent.id
  visibility_level                 = "private"
  remove_source_branch_after_merge = true
  default_branch                   = "master"
  import_url                       = "https://github.com/Krzychu-Z/rust-compiler.git"
}

resource "gitlab_branch_protection" "large_master" {
  project            = gitlab_project.large_project.id
  branch             = "master"
}

# --- pipelines-repository ---
resource "gitlab_project" "pipelines_repo" {
  name                             = var.pipelines_repository.name
  description                      = var.pipelines_repository.description
  namespace_id                     = data.gitlab_group.parent.id
  visibility_level                 = "private"
  initialize_with_readme           = true
  remove_source_branch_after_merge = true
  default_branch                   = "master"
}