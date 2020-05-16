output "id" {
  value       = aws_vpc.ninja.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public.*.id
  description = "List of public subnet ID"
}

output "private_subnet_ids" {
  value       = aws_subnet.private.*.id
  description = "List of private subnet ID"
}

output "cidr_block" {
  value       = var.cidr_block
  description = "The CIDR block associated with the VPC"
}

output "nat_gateway_ip" {
  value       = aws_eip.nat.*.public_ip
  description = "List of Elastic IPs associated with NAT gateways"
}
