variable "organization" {
  description = "Github free organization to keep testing resources inside"
  type = string
}

variable "email" {
  description = "Student mail to create Github organization"
  type = string
}

variable "small_project" {
  description = "Configuration for the small project repository"
  type = object({
    name        = string
    description = string
  })
}

variable "large_project" {
  description = "Configuration for the large project repository"
  type = object({
    name        = string
    description = string
  })
}

variable "pipelines_repository" {
  description = "Configuration for the pipelines repository"
  type = object({
    name        = string
    description = string
  })
}