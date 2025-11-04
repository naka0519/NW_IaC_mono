locals {
  name_prefix = coalesce(
    var.name,
    try(var.tags["Name"], null),
    var.vpc_id,
    "route"
  )
}

resource "aws_route_table" "public" {
  count  = var.igw_id == null ? 0 : 1
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route" "public_inet" {
  count                  = var.igw_id == null ? 0 : 1
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = var.igw_id == null ? {} : var.public_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  for_each = var.nat_ids
  vpc_id   = var.vpc_id
  tags     = merge(var.tags, { Name = "${local.name_prefix}-private-${each.key}-rt" })
}

resource "aws_route" "private_default" {
  for_each               = var.nat_ids
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = var.private_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private[replace(each.key, "private-", "")].id
}
