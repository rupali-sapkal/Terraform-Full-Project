variable "environment" {
  description = "Environment name"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "instance_ids" {
  description = "EC2 instance IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
