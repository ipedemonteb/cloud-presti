module "vpc" {
  source = "./modules/network"

  vpc_config = {
    name       = "cloud-presti-vpc"
    cidr_block = "10.0.0.0/16"
    region     = "us-east-1"
  }

  subnets_config = [
    # AZ a
    {
      name              = "public-az-a"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      nat_gateway       = true
    },
    {
      name              = "private-az-a-1"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1a"
    },
    # AZ b
    {
      name              = "public-az-b"
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1b"
      nat_gateway       = true
    },
    {
      name              = "private-az-b-1"
      cidr_block        = "10.0.5.0/24"
      availability_zone = "us-east-1b"
    },
  ]

  route_tables_config = [
    {
      name    = "public-rt-az-a"
      subnets = ["public-az-a"]
      routes = [{
        cidr_block = "0.0.0.0/0"
        target     = "igw"
      }]
    },
    {
      name    = "public-rt-az-b"
      subnets = ["public-az-b"]
      routes = [{
        cidr_block = "0.0.0.0/0"
        target     = "igw"
      }]
    },
    {
      name    = "private-rt-az-a"
      subnets = ["private-az-a-1"]
      routes = [{
        cidr_block = "0.0.0.0/0"
        target     = "nat"
      }]
    },
    {
      name    = "private-rt-az-b"
      subnets = ["private-az-b-1"]
      routes = [{
        cidr_block = "0.0.0.0/0"
        target     = "nat"
      }]
    },
  ]

  security_groups_config = [
    {
      name    = "lambda-sg"
      inbound = []
      outbound = [
        {
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          cidr_blocks = ["0.0.0.0/0"]
        },
      ]
    },
  ]
}
