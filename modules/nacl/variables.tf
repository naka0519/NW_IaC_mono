variable "name"               { type = string }
variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { 
    type = map(string) 
    default = {} 
}
variable "private_subnet_ids" { 
    type = map(string) 
    default = {} 
}
variable "rules"  { 
    type = any 
    default = {} 
}
variable "tags"   { 
    type = map(string) 
    default = {} 
}
