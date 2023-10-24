variable "region" {}
variable "accountId" {}
variable "callbackUrl" {}
variable "logoutUrl" {}
variable "aws_region" {
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    "us-east-1" = "ami-0fc5d935ebf8bc3bc"
  }
}