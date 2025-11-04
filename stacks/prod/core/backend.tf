terraform {
  backend "s3" {
    bucket         = "nw-iac-tfstate-global-20251101" # TODO: change to your bucket
    dynamodb_table = "tfstate-locks-global-20251101"  # TODO: change to your table lock false
    # use_lockfile   = false
    region         = "ap-northeast-1"
    key            = "network/prod-core/terraform.tfstate"
    encrypt        = true
  }
}
