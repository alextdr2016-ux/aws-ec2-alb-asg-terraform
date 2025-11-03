variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1" # pune regiunea ta obișnuită
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
  default     = "default"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR format (for SSH access)"
  default     = "81.196.29.58/32"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Name of your existing EC2 key pair (optional for SSH)"
  default     = "generalkeypair"
}


