resource "random_id" "random_id_prefix" {
  byte_length = 2
}

data "aws_availability_zones" "available" {
  state   = "available"
}

/*====
Variables used across all modules
======*/
locals {
  # production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
  production_availability_zones = "${data.aws_availability_zones.available.names}"
}

module "network" {
  source               = "./modules/network"
  region               = "${var.region}"
  availability_zones   = "${local.production_availability_zones}"
  environment          = "${var.environment}"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"

}

module "server" {
  source                  = "./modules/server"
  region                  = "${var.region}"
  availability_zones      = "${local.production_availability_zones}"
  environment             = "${var.environment}"
  aws_vpc_id              = "${module.network.aws_vpc_id}"
  security_groups_ids     = "${module.network.security_groups_ids}"
  public_subnet_id        = "${module.network.public_subnet_id}"
  private_subnet_id       = "${module.network.private_subnet_id}"
  ecs_key_pair_name       = "${var.ecs_key_pair_name}"
  container_port          = "${var.container_port}"
  JICOFO_COMPONENT_SECRET = "${var.JICOFO_COMPONENT_SECRET}"
  JICOFO_AUTH_PASSWORD    = "${var.JICOFO_AUTH_PASSWORD}"
  JVB_AUTH_PASSWORD       = "${var.JVB_AUTH_PASSWORD}"
  JIGASI_XMPP_PASSWORD    = "${var.JIGASI_XMPP_PASSWORD}"
  JIBRI_RECORDER_PASSWORD = "${var.JIBRI_RECORDER_PASSWORD}"
  JIBRI_XMPP_PASSWORD     = "${var.JIBRI_XMPP_PASSWORD}"
}
