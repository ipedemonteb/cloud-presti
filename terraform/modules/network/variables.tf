variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    name       = string
    cidr_block = string
    region     = string
  })
}

variable "subnets_config" {
  description = "List of CIDR blocks for the subnets"
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    nat_gateway       = optional(bool, false)
  }))
}

variable "route_tables_config" {
  description = "Route tables configuration"
  type = list(object({
    name    = string
    subnets = list(string)
    routes = list(object({
      cidr_block = string
      target     = string
    }))
  }))
  default = []
}

variable "security_groups_config" {
  description = "Security groups configuration"
  type = list(object({
    name = string
    inbound = list(object({
      protocol           = string
      from_port          = number
      to_port            = number
      cidr_blocks        = optional(list(string), [])
      security_group_ref = optional(string, null)
    }))
    outbound = list(object({
      protocol           = string
      from_port          = number
      to_port            = number
      cidr_blocks        = optional(list(string), [])
      security_group_ref = optional(string, null)
    }))
  }))
  default = []
}
