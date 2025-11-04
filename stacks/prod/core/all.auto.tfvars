env           = "prod"
account_alias = "core"

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
