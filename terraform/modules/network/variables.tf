variable "vpc_config" {
  description = "Configuracion de la VPC"
  type = object({
    name       = string
    cidr_block = string
    region     = string
  })
}

variable "subnets_config" {
  description = "Lista de CIDR blocks para las subnets"
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    nat_gateway       = optional(bool, false)
  }))
}

variable "route_tables_config" {
  description = "Configuracion de las route tables"
  type = list(object({
    name    = string
    subnets = list(string)
    routes  = list(object({
      cidr_block = string
      target     = string
    }))
  }))
  default = []
}

variable "security_groups_config" {
  description = "Configuracion de los security groups"
  type = list(object({
    name    = string
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
