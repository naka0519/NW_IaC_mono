// ap-northeast-1 用の region module
module "network_apne1" {
  source = "../../../modules/network"

  providers = {
    aws = aws.apne1
  }

  env           = var.env
  account_alias = var.account_alias
  region        = "ap-northeast-1"
  vpcs          = lookup(var.vpcs, "ap-northeast-1", {})
}


// ap-northeast-3 用の region module
module "network_apne3" {
  source = "../../../modules/network"

  providers = {
    aws = aws.apne3
  }

  env           = var.env
  account_alias = var.account_alias
  region        = "ap-northeast-3"
  vpcs          = lookup(var.vpcs, "ap-northeast-3", {})
}
