locals {
  public_ingress     = try(var.rules.public.ingress, [])
  public_egress      = try(var.rules.public.egress, [])
  private_ingress    = try(var.rules.private.ingress, [])
  private_egress     = try(var.rules.private.egress, [])
  create_public_acl  = (length(local.public_ingress) + length(local.public_egress)) > 0
  create_private_acl = (length(local.private_ingress) + length(local.private_egress)) > 0
}

resource "aws_network_acl" "public" {
  count  = local.create_public_acl ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-public-nacl" })
}

resource "aws_network_acl_rule" "public_ingress" {
  for_each = local.create_public_acl ? { for r in local.public_ingress : r.rule_no => r } : {}

  network_acl_id = aws_network_acl.public[0].id
  egress         = false
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from
  to_port        = each.value.to
}

resource "aws_network_acl_rule" "public_egress" {
  for_each = local.create_public_acl ? { for r in local.public_egress : r.rule_no => r } : {}

  network_acl_id = aws_network_acl.public[0].id
  egress         = true
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from
  to_port        = each.value.to
}

resource "aws_network_acl_association" "public_assoc" {
  for_each = local.create_public_acl ? var.public_subnet_ids : {}

  network_acl_id = aws_network_acl.public[0].id
  subnet_id      = each.value
}

resource "aws_network_acl" "private" {
  count  = local.create_private_acl ? 1 : 0
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-private-nacl" })
}

resource "aws_network_acl_rule" "private_ingress" {
  for_each = local.create_private_acl ? { for r in local.private_ingress : r.rule_no => r } : {}

  network_acl_id = aws_network_acl.private[0].id
  egress         = false
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from
  to_port        = each.value.to
}

resource "aws_network_acl_rule" "private_egress" {
  for_each = local.create_private_acl ? { for r in local.private_egress : r.rule_no => r } : {}

  network_acl_id = aws_network_acl.private[0].id
  egress         = true
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr
  from_port      = each.value.from
  to_port        = each.value.to
}

resource "aws_network_acl_association" "private_assoc" {
  for_each = local.create_private_acl ? var.private_subnet_ids : {}

  network_acl_id = aws_network_acl.private[0].id
  subnet_id      = each.value
}
