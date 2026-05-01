output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.vpc.id
}

output "subnet_ids" {
  description = "Mapa de cidr_block a ID de cada subnet"
  value       = { for cidr, subnet in aws_subnet.subnet : cidr => subnet.id }
}

output "nat_gateway_ids" {
  description = "Mapa de cidr_block a ID de cada NAT Gateway"
  value       = { for cidr, nat_gw in aws_nat_gateway.nat_gw : cidr => nat_gw.id }
}

output "route_table_ids" {
  description = "Mapa de nombre a ID de cada route table"
  value       = { for name, rt in aws_route_table.rt : name => rt.id }
}

output "security_group_ids" {
  description = "Mapa de nombre a ID de cada security group"
  value       = { for name, sg in aws_security_group.sg : name => sg.id }
}
