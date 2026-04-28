output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.main[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.main[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.main[*].public_ip
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}
