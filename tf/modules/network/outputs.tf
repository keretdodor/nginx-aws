output "private_subnets" {
  value       = [aws_subnet.nginx_private_subnet-1.id, aws_subnet.nginx_private_subnet-2.id]
  description = "List of private subnet IDs"
}

output "public_subnets" {
  value       = [aws_subnet.nginx_public_subnet-1.id, aws_subnet.nginx_public_subnet-2.id]
  description = "List of private subnet IDs"
}

output "vpc_id" {
  value = aws_vpc.nginx_vpc.id
  description = "The vpc's id"
}

output "bastion_private_ip" {
  value = aws_instance.nginx_bastion.private_ip
  description = "The private IP address of the bastion host"
}

output "bastion_public_ip" {
  value = aws_instance.nginx_bastion.public_ip
  description = "The private IP address of the bastion host"
}
