
# Avilability zones

variable "az_names" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  description = "Required avilability zones"
}

# Public Subnet cidr

variable "public_subnet_cidr" { 
  type        = list(string)
  default     = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
  description = "Required public subnet"
}

# Private subnet cidr

variable "private_subnet_cidr" {
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
  description = "Required private subnets"
}


