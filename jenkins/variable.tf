### define variable su dung
## vpc
variable "project" {
  type    = string
  default = "felipeworkshop1111111"
}
variable "environment" {
  type    = string
  default = "trung"
}

variable "cidr_vpc" {
  type    = string
  default = "10.0.0.0/16"
}



