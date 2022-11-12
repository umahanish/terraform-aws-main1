variable "instance_type" {
  type = string
}

variable "dev_ami" {
  type = string
  default = "ami-051dfed8f67f095f5"
}

variable "instance_count" {
  type = string
  default = "2"
}

/*variable "key_name" {
  type = string
}*/
variable "demo_key_name" {
  type        = string
  default     = "terraform-key-pair"
  description = "Key-pair demo by Terraform"
}

variable "availability_zones" {
  type = list(string)
}

variable "cidr_block" {
  type        = string
  default     = "10.10.0.0/16"
  description = "VPC cidr block. Example: 10.10.0.0/16"
}

variable "workstation_ip" {
  type = string
  default = "0.0.0.0/0"
}
