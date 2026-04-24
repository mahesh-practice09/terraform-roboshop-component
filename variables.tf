variable "environment" {
  type = string
  default = "sbx"
}

variable "Project" {
  type = string
  default = "roboshop"
}


variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "zone_id" {
  type = string 
  default = "Z01154241BNSMMPVQO32W"
}

variable "domain_name" {
  type = string 
  default = "daws88s.shop"
}

variable "component" {
  
}

# variable "sg_id" {
#   type = map(list)
# }

variable "health_check_path" {
  type = string
  default = "/health"
}

variable "rule_priority" {
  
}