variable "aws_role_arn" {
  description = "The ARN of the AWS IAM Role to assume for deploying resources."
  type        = string
}
variable "bucket_name" {
  description = "The name of the S3 bucket to create for storing results."
  type        = string
}
variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
}