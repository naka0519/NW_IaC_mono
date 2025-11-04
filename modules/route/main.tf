locals {
  name_prefix = coalesce(
    var.name,
    try(var.tags["Name"], null),
    var.vpc_id,
    "route"
  )
  has_public_subnets = length(var.public_subnet_ids) > 0
  has_nat_gateways   = length(var.nat_ids) > 0
}

resource "aws_route_table" "public" {
  count  = local.has_public_subnets ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route" "public_inet" {
  count                  = local.has_public_subnets ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = local.has_public_subnets ? var.public_subnet_ids : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  for_each = local.has_nat_gateways ? var.nat_ids : {}
  vpc_id   = var.vpc_id
  tags     = merge(var.tags, { Name = "${local.name_prefix}-private-${each.key}-rt" })
}

resource "aws_route" "private_default" {
  for_each               = local.has_nat_gateways ? var.nat_ids : {}
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = local.has_nat_gateways ? var.private_subnet_ids : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.private[replace(each.key, "private-", "")].id
}
