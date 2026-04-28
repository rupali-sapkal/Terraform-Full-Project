output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = module.alb.alb_dns_name
}

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_instance_public_ips" {
  description = "EC2 instance public IPs"
  value       = module.ec2.instance_public_ips
}

output "app_bucket_name" {
  description = "S3 application bucket name"
  value       = module.s3.app_bucket_name
}

output "terraform_state_bucket" {
  description = "Terraform state bucket name"
  value       = module.s3.terraform_state_bucket_name
}
