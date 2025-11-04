
provider "aws" {
  alias   = "apne1"
  region  = "ap-northeast-1"
  # profile = "yoshi" # TODO: change or replace with assume_role below

  # Alternative:
  # assume_role {
  #   role_arn     = "arn:aws:iam::<ACCOUNT_ID>:role/OrganizationAccountAccessRole"
  #   session_name = "tf-network"
  # }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Env       = var.env
      Account   = var.account_alias
    }
  }
}

provider "aws" {
  alias  = "apne3"
  region = "ap-northeast-3"
  # profile = "prod-core"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Env       = var.env
      Account   = var.account_alias
    }
  }
}