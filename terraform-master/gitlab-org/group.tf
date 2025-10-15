data "gitlab_group" "parent" {
  full_path = var.parent_group_path
}