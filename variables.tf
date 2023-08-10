variable "prefix" {
 type        = string
 description = "prefix to apply to resources"
 default     = "<your prefix>"
}

variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 //CIDR ranges
 default     = ["<your public CIDR vaues>",...]
 //default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 //CIDR ranges
 default     = ["<your private CIDR vaues>",...]
 //default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["<your AZs>",...]
 //default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
