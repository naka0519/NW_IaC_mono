locals {
  config_enabled = var.config.enable
  create_nat     = var.config.per_az && local.config_enabled
  name_prefix    = coalesce(try(var.config.name, null), var.vpc_id, "nat")
  config_tags    = try(var.config.tags, {})
  effective_tags = merge(var.tags, local.config_tags)
  target_subnets = local.create_nat ? var.public_subnets : {}
}

resource "aws_eip" "this" {
  for_each = local.target_subnets

  domain = "vpc"
  tags = merge(
    local.effective_tags,
    { Name = "${local.name_prefix}-${each.key}-eip" }
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.target_subnets

  subnet_id     = each.value
  allocation_id = aws_eip.this[each.key].id
  tags = merge(
    local.effective_tags,
    { Name = "${local.name_prefix}-${each.key}-nat" }
  )
}
