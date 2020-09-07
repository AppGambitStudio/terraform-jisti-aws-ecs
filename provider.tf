provider "aws" {
  region  = "${var.region}"
  profile = "<AWS_CLI_PROFILE_NAME>" //If you run this script using AWS EC2 of CodePipeline remove this line
}