env           = "prod"
account_alias = "core"
# core_account_id = "123456789012"      # core アカウント ID
# core_role_name  = "TerraformNetworkRole"

# region -> vpc_name -> 設定 のマップ
vpcs = {
  ap-northeast-1 = {
    main = {
      cidr = "10.10.0.0/16"

      public_subnets = {
        pub-a = { cidr = "10.10.0.0/24", az = "ap-northeast-1a" }
      }

      private_subnets = {
        pri-a = { cidr = "10.10.10.0/24", az = "ap-northeast-1a" }
      }

      nat = {
        per_az = false
        enable = false
      }
      nacl = {}
      tags = { Name = "main" }
    }
  }

  #   ap-northeast-3 = {
  #     main = {
  #       cidr = "10.20.0.0/16"

  #       public_subnets = {
  #         pub-a = { cidr = "10.20.0.0/24",  az = "ap-northeast-3a" }
  #       }

  #       private_subnets = {
  #         pri-a = { cidr = "10.20.10.0/24", az = "ap-northeast-3a" }
  #       }

  #       nat  = {
  #         per_az = false
  #         enable = false
  #       }
  #       nacl = {}
  #       tags = { Name = "main" }
  #     }
  #   }
}
