# 環境とアカウント名
variable "env" {
  type = string
}

variable "account_alias" {
  type = string
}

# core アカウント（組織アカウント）の ID と Role 名を変数化しておく
variable "core_account_id" {
  type = string
}

variable "core_role_name" {
  type    = string
  default = "TerraformNetworkRole"
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
          enable = bool
        })
        nacl = map(any)
        tags = map(string)
      })
    )
  )
}
