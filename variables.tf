#example : fill your information
variable "region" {
  description = "Region"
}

variable "environment" {
  description = "The environment"
}

variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "The CIDR block for the private subnet"
}


variable "ecs_key_pair_name" {
  default = "AG-ap-south-1"
}

variable "container_port" {
  default = "443"
}

variable "memory_reserv" {
  default = 100
}

variable "JICOFO_COMPONENT_SECRET" {
  description = "JICOFO_COMPONENT_SECRET"
}

variable "JICOFO_AUTH_PASSWORD" {
  description = "JICOFO_AUTH_PASSWORD"
}

variable "JVB_AUTH_PASSWORD" {
  description = "JVB_AUTH_PASSWORD"
}

variable "JIGASI_XMPP_PASSWORD" {
  description = "JIGASI_XMPP_PASSWORD"
}

variable "JIBRI_RECORDER_PASSWORD" {
  description = "JIBRI_RECORDER_PASSWORD"
}

variable "JIBRI_XMPP_PASSWORD" {
  description = "JIBRI_XMPP_PASSWORD"
}
