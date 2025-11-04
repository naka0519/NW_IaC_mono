variable "vpc_id" { type = string }

variable "public_subnets" {
  type    = map(string)
  default = {}
}

variable "config" {
  type = object({
    per_az = bool
    enable = optional(bool)
    name   = optional(string)
    tags   = optional(map(string))
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
