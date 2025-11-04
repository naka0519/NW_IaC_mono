variable "name"              { type = string }
variable "public_subnet_ids" { type = map(string) }
variable "enable"            { 
    type = bool 
    default = true 
}
variable "tags"              { 
    type = map(string) 
    default = {} 
}
