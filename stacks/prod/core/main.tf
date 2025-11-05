locals {
  region_providers = {
    # リージョン追加ごとにここに追記
    ap-northeast-1 = aws.apne1
    ap-northeast-3 = aws.apne3
  }
}

module "network" {
  for_each = var.vpcs

  source = "../../../modules/network"

  providers = {
    aws = local.region_providers[each.key]
  }

  env           = var.env
  account_alias = var.account_alias
  region        = each.key
  vpcs          = each.value
}
