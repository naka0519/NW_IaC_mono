locals {
  name_prefix = coalesce(
    var.name,
    try(var.tags["Name"], null),
    var.vpc_id,
    "subnet"
  )
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = try(each.value.map_public_ip_on_launch, false)
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}"
    Type = "private"
  })
}
