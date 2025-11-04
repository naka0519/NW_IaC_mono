// modules/network/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "env"           { type = string }
variable "account_alias" { type = string }
variable "region"        { type = string }

variable "vpcs" {
  type = map(object({
    cidr            = string
    public_subnets  = map(object({ cidr = string, az = string }))
    private_subnets = map(object({ cidr = string, az = string }))
    nat             = object({ per_az = bool })
    nacl            = map(any)
    tags            = map(string)
  }))
}

locals {
  vpcs = var.vpcs
}

module "vpc" {
  for_each = local.vpcs

  source     = "../vpc"
  name       = "${var.env}-${var.account_alias}-${var.region}-vpc-${each.key}"
  cidr_block = each.value.cidr
  tags = merge(each.value.tags, {
    Env     = var.env
    Account = var.account_alias
    Region  = var.region
  })
}

module "subnet" {
  for_each = local.vpcs

  source          = "../subnet"
  vpc_id          = module.vpc[each.key].id
  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets
}

module "igw" {
  for_each = local.vpcs

  source = "../igw"

  vpc_id = module.vpc[each.key].id
  name   = "${var.env}-${var.account_alias}-${var.region}-igw-${each.key}"
  tags   = { Env = var.env }
}

module "nat" {
  for_each = local.vpcs

  source = "../nat"

  vpc_id         = module.vpc[each.key].id
  public_subnets = module.subnet[each.key].public_subnet_ids
  config         = each.value.nat
}

module "route" {
  for_each = local.vpcs

  source = "../route"

  vpc_id             = module.vpc[each.key].id
  igw_id             = module.igw[each.key].id
  public_subnet_ids  = module.subnet[each.key].public_subnet_ids
  private_subnet_ids = module.subnet[each.key].private_subnet_ids
  nat_ids            = module.nat[each.key].nat_ids
}

module "nacl" {
  for_each = local.vpcs

  source = "../nacl"

  name               = "${var.env}-${var.account_alias}-${var.region}-${each.key}"
  vpc_id             = module.vpc[each.key].id
  public_subnet_ids  = module.subnet[each.key].public_subnet_ids
  private_subnet_ids = module.subnet[each.key].private_subnet_ids
  rules              = each.value.nacl
  tags               = { Env = var.env }
}
