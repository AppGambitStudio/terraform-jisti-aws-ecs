output "public_route_table" {
  value = "${aws_default_route_table.public.id}"
}

output "aws_vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private.*.id}"
}

output "security_groups_ids" {
  value = ["${aws_security_group.default.id}"]
}
