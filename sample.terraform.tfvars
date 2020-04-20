region            = "<Region>"
ecs_key_pair_name = "<SSH Key for EC2>"

environment = "production"

/* module networking */
vpc_cidr             = "<CIRD ranger for VPC>"
public_subnets_cidr  = "Public Subnet CIDR ranger" //["10.30.1.0/24", "10.30.2.0/24"]
private_subnets_cidr = "Private Subnet CIDR ranger" //["10.30.10.0/24", "10.30.20.0/24"]


//For All variables value run ./get-password.sh command
JICOFO_COMPONENT_SECRET = ""
JICOFO_AUTH_PASSWORD    = ""
JVB_AUTH_PASSWORD       = ""
JIGASI_XMPP_PASSWORD    = ""
JIBRI_RECORDER_PASSWORD = ""
JIBRI_XMPP_PASSWORD     = ""
