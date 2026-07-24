output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the load balancer and ECS tasks"
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}
