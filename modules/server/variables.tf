variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zones" {
  type        = list
  description = "The az that the resources will be launched"
}

variable "environment" {
  description = "The environment"
}

variable "aws_vpc_id" {
  description = "aws vpc id"
}

variable "public_subnet_id" {
  type        = list
  description = "public subnets"
}

variable "private_subnet_id" {
  type        = list
  description = "private subnets"
}

variable "ecs_key_pair_name" {
  description = "ecs_key_pair_name"
}

variable "container_port" {
  description = "container port"
}

variable "security_groups_ids" {
  type        = list
  description = "The SGs to use"
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
