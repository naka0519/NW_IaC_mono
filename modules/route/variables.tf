variable "name"               { type = string }
variable "vpc_id"             { type = string }
variable "igw_id"             { 
    type = string 
    nullable = true 
}
variable "public_subnet_ids"  { 
    type = map(string) 
    default = {} 
}
variable "private_subnet_ids" { 
    type = map(string) 
    default = {} 
}
variable "nat_ids"            { 
    type = map(string) 
    default = {} 
}
variable "tags"               { 
    type = map(string) 
    default = {} 
}
