# Advanced Configuration Guide

## Custom Variable Overrides

You can override variables using `-var` flag or additional `.tfvars` files.

### Using -var Flag

```bash
# Override single variable
terraform plan -var="instance_count=4" -var-file="terraform.tfvars"

# Override multiple variables
terraform apply \
  -var="instance_type=t3.small" \
  -var="instance_count=5" \
  -var="root_volume_size=50" \
  -var-file="terraform.tfvars"
```

### Using Additional tfvars File

Create `override.tfvars`:
```hcl
instance_count   = 4
instance_type    = "t3.small"
root_volume_size = 50
```

Apply with both files:
```bash
terraform apply \
  -var-file="terraform.tfvars" \
  -var-file="override.tfvars"
```

## Custom User Data Scripts

### Modify EC2 User Data

Edit `environments/dev/terraform.tfvars`:

```hcl
user_data = <<-EOF
#!/bin/bash
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.0.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install additional tools
yum install -y git curl wget nodejs npm

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Clone application
git clone https://github.com/example/app.git .

# Start application
docker-compose up -d
EOF
```

## Network Customization

### Add Custom CIDR Blocks

Modify `environments/dev/terraform.tfvars`:

```hcl
vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"  # Add third subnet
]

private_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.11.0/24",
  "10.0.12.0/24"  # Add third subnet
]

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"  # Add third AZ
]
```

### Enable VPC Flow Logs

Add to `modules/vpc/main.tf`:

```hcl
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.environment}"
  retention_in_days = 7
}
```

## Security Enhancements

### Add HTTPS Support

Add to ALB module:

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

### Restrict SSH Access

Modify security group:

```hcl
resource "aws_security_group" "ec2" {
  # ... existing config ...

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/32"]  # Your IP only
  }
}
```

## Monitoring & Logging

### Enable CloudWatch Monitoring

Add to EC2 module:

```hcl
resource "aws_cloudwatch_agent_config" "ec2" {
  logs_config {
    logs_collected {
      files {
        collect_list {
          file_path       = "/var/log/httpd/access_log"
          log_group_name  = "/aws/ec2/${var.environment}/apache-access"
          log_stream_name = "{instance_id}"
        }
      }
    }
  }
}
```

### Create CloudWatch Alarms

Add to environments configuration:

```hcl
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Advanced Tagging

### Implement Comprehensive Tags

Add to provider.tf:

```hcl
default_tags {
  tags = {
    Project       = "TerraformProject"
    Environment   = var.environment
    ManagedBy     = "Terraform"
    CostCenter    = "Engineering"
    Owner         = "DevOps"
    Compliance    = "Required"
    BackupPolicy  = "Daily"
    CreatedAt     = timestamp()
    CreatedBy     = data.aws_caller_identity.current.arn
  }
}
```

## Cost Optimization

### Use Spot Instances for Dev

Modify EC2 module:

```hcl
resource "aws_instance" "main" {
  # ... existing config ...

  instance_market_options {
    market_type = "spot"
  }

  # Save ~70% on compute costs
  spot_price = "0.015"  # max price
}
```

### Auto-Scaling Configuration

Add to modules/ec2:

```hcl
resource "aws_launch_configuration" "main" {
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  # ... other config ...
}

resource "aws_autoscaling_group" "main" {
  launch_configuration = aws_launch_configuration.main.id
  min_size             = 2
  max_size             = 10
  desired_capacity     = var.instance_count
  vpc_zone_identifier  = var.subnet_ids
}
```

## Backup & Disaster Recovery

### Enable RDS Backups (if adding RDS)

```hcl
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  multi_az                = true
  
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.environment}-final-snapshot"
}
```

### Enable EC2 EBS Snapshots

```hcl
resource "aws_dlm_lifecycle_policy" "ebs_backup" {
  execution_role_arn = aws_iam_role.dlm.arn
  description        = "Daily EBS snapshots"
  state               = "ENABLED"

  policy_details {
    policy_type = "EBS_SNAPSHOT_MANAGEMENT"

    resource_types = ["VOLUME"]

    schedules {
      name = "Daily Snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
      }

      retain_rule {
        count = 7
      }
    }
  }
}
```

## Multi-Region Deployment

### Deploy to Multiple Regions

Create `environments/prod-eu`:

```hcl
# provider.tf
provider "aws" {
  region = "eu-west-1"  # Europe region
}

# backend
backend "s3" {
  bucket = "terraform-state-prod-eu-ACCOUNT_ID"
  key    = "prod-eu/terraform.tfstate"
}
```

Deploy:

```bash
cd environments/prod-eu
terraform init
terraform apply
```

## Disaster Recovery Testing

### Test Infrastructure Failover

```bash
# Simulate failure
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Monitor failover
watch -n 5 'aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...'

# Restore
aws ec2 start-instances --instance-ids i-0123456789abcdef0
```

---

For more information, see [README.md](README.md) and [DEPLOYMENT.md](DEPLOYMENT.md).
