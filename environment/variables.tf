variable "aws_role_arn" {
  description = "The ARN of the AWS IAM Role to assume for deploying resources."
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket to create for storing results."
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "masters-thesis-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for the managed node group"
  type        = string
  default     = "t3.large"
}