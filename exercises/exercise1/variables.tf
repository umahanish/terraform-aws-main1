variable "region" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "demo_key_name" {
  #type = string
}
/*variable "demo_key_name" {
  type        = string
  default     = "studyit-keypair"
  description = "Key-pair demo by Terraform"
}*/

variable "availability_zones" {
  type = list(string)
}

variable "workstation_ip" {
  type = string
  default = "0.0.0.0/0"
}

variable "amis" {
  type = map(any)
  default = {
    "eu-west-2" : "ami-0648ea225c13e0729"
    "us-west-2" : "ami-0cea098ed2ac54925"
  }
}