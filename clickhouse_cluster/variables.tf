variable "app" {
  type = string
}

variable "name" {
  type = string
}

variable "key_pair" {
  type = string
}

variable "env" {
  default = "dev"
  type    = string
}

variable "instance_type" {
  default = "t3.micro"
  type    = string
}

variable "private_key" {
  type = string
}

# Network configuration
variable "subnet_id" {
  type = string
}

variable "security_groups" {
  type = list(string)
}
