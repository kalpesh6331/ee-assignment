variable "aws_access_key" {
	description = "AWS Access Key"
	default     = ""
}

variable "aws_secret_key" {
	description = "AWS Secret Key"
	default     = ""
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = ""
}

variable "ubuntu_ami" {
  default = ""
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "172.20.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "172.20.10.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "172.20.20.0/24"
}

variable "public_key_path" {
	description = "Public key for the instances in RSA format"
	default = ""
}

variable "private_key_path" {
  description = "Required for performing installations on instances"
  default = ""
}

variable "docker_playbook_path" {
  default = ""
}