# IAM Role and Instance Profile for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Attach policy for S3 access
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.environment}-ec2-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3.app_bucket_arn,
          "${module.s3.app_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach SSM policy for Systems Manager
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
  environment           = var.environment
}

# Security Group Module
module "security_group" {
  source = "../../modules/security_group"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  environment = var.environment
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  environment                = var.environment
  instance_type              = var.instance_type
  instance_count             = var.instance_count
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_id          = module.security_group.ec2_security_group_id
  iam_instance_profile_name  = aws_iam_instance_profile.ec2_profile.name
  user_data                  = var.user_data
  root_volume_size           = var.root_volume_size
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  environment           = var.environment
  security_group_id     = module.security_group.alb_security_group_id
  subnet_ids            = module.vpc.public_subnet_ids
  instance_ids          = module.ec2.instance_ids
  vpc_id                = module.vpc.vpc_id
}
