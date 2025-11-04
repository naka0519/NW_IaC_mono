output "nat_ids" { value = { for k, n in aws_nat_gateway.this : k => n.id } }
