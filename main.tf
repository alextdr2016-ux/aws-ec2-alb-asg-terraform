terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
# VPC-ul implicit din cont (ca în Console când nu creezi unul custom)
data "aws_vpc" "default" {
  default = true
}

# Toate subrețelele din VPC-ul implicit
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Alegem primele 2 subrețele pentru ALB (multi-AZ)
locals {
  alb_subnets = slice(data.aws_subnets.default_vpc_subnets.ids, 0, 2)
}
# AMI Amazon Linux 2023 (x86_64) mereu actualizat, luat din SSM
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
# Security Group pentru Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Security Group pentru EC2 (primește trafic doar de la ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-web-sg"
  description = "Allow HTTP only from ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # (opțional) SSH doar de la IP-ul tău
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
# Launch Template = "rețeta" din care se vor crea toate instanțele EC2
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  user_data = base64encode(file("${path.module}/user_data.sh"))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # (opțional) key pair dacă vrei SSH
  key_name = var.key_name
}
# Auto Scaling Group: menține între 2 și 4 instanțe EC2
resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  min_size                  = 2
  desired_capacity          = 3
  max_size                  = 4

  # Subrețelele în care pornește instanțele (aceleași 2 ca ALB)
  vpc_zone_identifier       = local.alb_subnets

  # Folosește health check-urile ALB/Target Group pentru a decide dacă o instanță e sănătoasă
  health_check_type         = "ELB"
  health_check_grace_period = 60

  # Rețeta instanței
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  # Atașează instanțele la Target Group-ul ALB
  target_group_arns = [aws_lb_target_group.web_tg.arn]

  # Tag vizibil în EC2 → Name=web-asg-instance
  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }

  # Creează noul ASG înainte să-l distrugă pe cel vechi (siguranță la update)
  lifecycle {
    create_before_destroy = true
  }
}
# Target Group: grupul de instanțe unde ALB trimite traficul
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.alb_subnets
}
resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
