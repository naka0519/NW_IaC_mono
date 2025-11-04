# 環境とアカウント名
variable "env" {
  type = string
}

variable "account_alias" {
  type = string
}

# region -> vpc -> 設定 のマップ
variable "vpcs" {
  description = "Region -> VPC -> settings"
  type = map( # region
    map(      # vpc name
      object({
        cidr = string
        public_subnets = map(object({
          cidr                    = string
          az                      = string
          map_public_ip_on_launch = optional(bool)
        }))
        private_subnets = map(object({
          cidr = string
          az   = string
        }))
        nat = object({
          per_az = bool
        })
        nacl = map(any)
        tags = map(string)
      })
    )
  )
}
