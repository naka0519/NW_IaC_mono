resource "aws_eip" "this" {
  for_each = var.enable ? var.public_subnet_ids : {}
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-${each.key}-eip" })
}

resource "aws_nat_gateway" "this" {
  for_each      = var.enable ? var.public_subnet_ids : {}
  subnet_id     = each.value
  allocation_id = aws_eip.this[each.key].id
  tags          = merge(var.tags, { Name = "${var.name}-${each.key}-nat" })
}
