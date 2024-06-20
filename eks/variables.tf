variable "eks_public_subnet_cidrs" {
  type        = map(string)
  description = "EKS Public Subnet CIDRs"

  default = {
    "us-east-1a" = "10.0.0.0/24",
    "us-east-1b" = "10.0.1.0/24",
    "us-east-1c" = "10.0.2.0/24"
  }
}

variable "eks_private_subnet_cidrs" {
  type        = map(string)
  description = "EKS Private Subnet CIDRs"

  default = {
    "us-east-1a" = "10.0.3.0/24",
    "us-east-1b" = "10.0.4.0/24",
    "us-east-1c" = "10.0.5.0/24"
  }
}