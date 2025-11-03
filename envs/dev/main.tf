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
  region  = "eu-north-1"
  profile = "default"
}

module "app" {
  source = "../../modules/app"

  # Variabile modul
  instance_type = "t3.micro"
  key_name      = "generalkeypair"
  my_ip_cidr    = "81.196.29.58/32" # pune IP-ul tău public/32

  min_size         = 2
  desired_capacity = 2
  max_size         = 4
}

output "alb_dns_name" {
  value = module.app.alb_dns_name
}
