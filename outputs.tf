output "alb_dns_name" {
  description = "Public DNS of the Load Balancer"
  value       = aws_lb.alb.dns_name
}
