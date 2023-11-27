variable "vpc" {
  description = "name of the vpc where the cluster is hosted"
}

variable "subnet-1" {
  description = "name of the private subnet in availibility zone A"
}

variable "subnet-2" {
  description = "name of the private subnet in availibility zone B"
}

variable "public_cidr" {
  description = "cidr block of the public subnet to open the incoming traffic for the bastion hosts"
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_accounts" {
  description = "List of account maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}