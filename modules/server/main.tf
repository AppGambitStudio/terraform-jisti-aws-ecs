data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_by_ecr" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

locals {
  target_groups = ["primary", "secondary"]
  hosts_name    = ["*.yourdomain.com"] #example : fill your information
}

resource "aws_security_group" "alb" {
  name   = "${var.environment}-allow-http"
  vpc_id = "${var.aws_vpc_id}"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-allow-http"
  }
}

resource "aws_lb" "this" {
  name               = "${var.environment}-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = flatten(["${var.security_groups_ids}", "${aws_security_group.alb.id}", "${aws_security_group.ecs.id}"])
  # security_groups    = ["${aws_security_group.alb.id}"]
  subnets = "${var.public_subnet_id}"

  tags = {
    Name = "${var.environment}-service-alb"
  }
}

resource "aws_lb_target_group" "this" {
  count = "${length(local.target_groups)}"
  name  = "${var.environment}-tg-${element(local.target_groups, count.index)}"

  port        = 8443
  protocol    = "HTTPS"
  vpc_id      = "${var.aws_vpc_id}"
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
    path                = "/"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
    timeout             = "5"
    interval            = "30"

  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_lb.this"]
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.0.arn}"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.0.arn}"
  }
}

# resource "aws_lb_listener_rule" "this" {
#   count        = 2
#   listener_arn = "${aws_lb_listener.this.arn}"

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.this.*.arn[count.index]}"
#   }

#   condition {
#     field  = "host-header"
#     values = "${local.hosts_name}"
#   }
# }

resource "aws_lb_listener_certificate" "example" {
  listener_arn    = "${aws_lb_listener.https.arn}"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "meet.appgambit.com"
  validation_method = "DNS"
  tags = {
    Environment = "test"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.environment}"
  task_definition = "${aws_ecs_task_definition.this.id}"
  cluster         = "${aws_ecs_cluster.this.arn}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.this.0.arn}"
    container_name   = "web"
    container_port   = "${var.container_port}"
  }

  launch_type                        = "EC2"
  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = ["aws_lb_listener.this"]
}

data "template_file" "test_def1" {
  template = "${file("${path.module}/testdefination/taskdef.json")}"

  vars = {
    JICOFO_COMPONENT_SECRET = "${var.JICOFO_COMPONENT_SECRET}"
    JICOFO_AUTH_PASSWORD    = "${var.JICOFO_AUTH_PASSWORD}"
    JVB_AUTH_PASSWORD       = "${var.JVB_AUTH_PASSWORD}"
    JIGASI_XMPP_PASSWORD    = "${var.JIGASI_XMPP_PASSWORD}"
    JIBRI_RECORDER_PASSWORD = "${var.JIBRI_RECORDER_PASSWORD}"
    JIBRI_XMPP_PASSWORD     = "${var.JIBRI_XMPP_PASSWORD}"
  }
}

data "template_file" "test_def" {
  template = "${file("${path.module}/testdefination/containerdef.json")}"

  vars = {
    JICOFO_COMPONENT_SECRET = "${var.JICOFO_COMPONENT_SECRET}"
    JICOFO_AUTH_PASSWORD    = "${var.JICOFO_AUTH_PASSWORD}"
    JVB_AUTH_PASSWORD       = "${var.JVB_AUTH_PASSWORD}"
    JIGASI_XMPP_PASSWORD    = "${var.JIGASI_XMPP_PASSWORD}"
    JIBRI_RECORDER_PASSWORD = "${var.JIBRI_RECORDER_PASSWORD}"
    JIBRI_XMPP_PASSWORD     = "${var.JIBRI_XMPP_PASSWORD}"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.environment}"
  execution_role_arn       = "${aws_iam_role.execution_role.arn}"
  task_role_arn            = "${aws_iam_role.task_role.arn}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  container_definitions    = "${data.template_file.test_def.rendered}"

  #   container_definitions    = <<DEFINITION
  # [
  #    {
  #       "portMappings": [
  #         {
  #           "hostPort": 0,
  #           "protocol": "tcp",
  #           "containerPort": ${var.container_port}
  #         }
  #       ],
  #       "environment": [
  #         {
  #           "name": "PORT",
  #           "value": "${var.container_port}"
  #         },
  #         {
  #           "name" : "APP_NAME",
  #           "value": "${var.environment}"
  #         }
  #       ],
  #       "memoryReservation" : ${var.memory_reserv},
  #       "image": "gnokoheat/ecs-nodejs-initial:latest",
  #       "name": "${var.environment}"
  #     }
  # ]
  # DEFINITION
}

data "aws_iam_policy_document" "assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    sid    = "AllowECRLogging"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task_role" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = ["${aws_ecs_cluster.this.arn}"]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.environment}_ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_ecs.json}"
}

resource "aws_iam_role_policy" "execution_role" {
  role   = "${aws_iam_role.execution_role.name}"
  policy = "${data.aws_iam_policy_document.execution_role.json}"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.environment}_ecsTaskRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_ecs.json}"
}

resource "aws_iam_role_policy" "task_role" {
  role   = "${aws_iam_role.task_role.name}"
  policy = "${data.aws_iam_policy_document.task_role.json}"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.environment}_cluster"
}

resource "aws_security_group" "ecs" {
  name   = "${var.environment}-allow-ecs"
  vpc_id = "${var.aws_vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 4443
  #   to_port     = 4443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10000
    to_port     = 10000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = ["${aws_security_group.alb.id}"]
  }


  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "latest-ecs" {
  most_recent = true
  # owners    = ["${data.aws_caller_identity.current.account_id}"] # Amazon

  # owners      = ["591542846629"] # Amazon
  # filter {
  #   name = "name"
  #   ["amzn2-ami-ecs-hvm-*"]
  # }

  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }

  owners = ["amazon"]

  filter {
    name = "name"
    # values=["amzn-ami-*-amazon-ecs-optimized"]
    # values = ["amzn2-ami-ecs-hvm-*"]
    values = ["*-ecs-optimized*"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_launch_configuration" "this" {
  name     = "ECS-Instance-${var.environment}"
  image_id = "${data.aws_ami.latest-ecs.id}"
  instance_type        = "m4.xlarge"
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.id}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups             = ["${aws_security_group.ecs.id}"]
  associate_public_ip_address = "true"
  key_name                    = "${var.ecs_key_pair_name}"
  user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${var.environment}_cluster >> /etc/ecs/ecs.config
                                  EOF
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.environment}-ecs-autoscaling-group"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = "${var.private_subnet_id}"
  # vpc_zone_identifier  = "${var.public_subnet_id}"
  launch_configuration = "${aws_launch_configuration.this.name}"
  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "ECS-Instance-${var.environment}-service"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "ecs-instance-role" {
  name               = "${var.environment}-ecs-instance-role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

data "aws_iam_policy_document" "ecs-instance-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = "${aws_iam_role.ecs-instance-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "${var.environment}-ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs-instance-role.id}"
}
