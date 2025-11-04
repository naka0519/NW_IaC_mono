variable "name" {
  type    = string
  default = null
}
variable "vpc_id" { type = string }
variable "public_subnets" {
  type    = map(object({ cidr = string, az = string, map_public_ip_on_launch = optional(bool) }))
  default = {}
}
variable "private_subnets" {
  type    = map(object({ cidr = string, az = string }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
