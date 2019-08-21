provider "aws" {
  version = "~> 1.60"
}

terraform {
  required_version = "< 0.12.0"
}

variable "cluster_name" {}

variable "cluster_host" {}

variable "instances" {
  type = "list"
}

variable "use_route53" {
  default     = true
  description = "Indicate whether or not to enable route53"
}

resource "aws_security_group" "k8s_api_security" {
  name        = "k8s-api-${var.cluster_name}-allow-all-${data.terraform_remote_state.pks.vpc_id}"
  description = "Allow all inbound traffic to k8s masters for ${var.cluster_name} API server"
  vpc_id      = "${data.terraform_remote_state.pks.vpc_id}"

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(data.terraform_remote_state.pks.tags, map("Name", "k8s-api-${var.cluster_name}-allow-all-${data.terraform_remote_state.pks.vpc_id}"))}"
}

resource "aws_elb" "k8s_api" {
  name                      = "k8s-api-${var.cluster_name}"
  cross_zone_load_balancing = true

  instances = "${var.instances}"

  health_check {
    healthy_threshold   = 6
    unhealthy_threshold = 3
    interval            = 5
    target              = "TCP:8443"
    timeout             = 3
  }

  idle_timeout = 3600

  listener {
    instance_port     = 8443
    instance_protocol = "tcp"
    lb_port           = 8443
    lb_protocol       = "tcp"
  }

  tags            = "${data.terraform_remote_state.pks.tags}"
  security_groups = ["${aws_security_group.k8s_api_security.id}"]
  subnets         = ["${data.terraform_remote_state.pks.public_subnets}"]
}

resource "aws_route53_record" "pks_api_dns" {
  zone_id = "${data.terraform_remote_state.pks.dns_zone_id}"
  name    = "${var.cluster_host}"
  type    = "A"

  alias {
    name                   = "${aws_elb.k8s_api.dns_name}"
    zone_id                = "${aws_elb.k8s_api.zone_id}"
    evaluate_target_health = true
  }

  count = "${var.use_route53 ? 1 : 0}"
}

data "terraform_remote_state" "pks" {
  backend = "local"

  config {
    path = "${path.module}/../env-state-aws/terraform.tfstate"
  }
}

output "cluster_host" {
  value = "${var.cluster_host}"
}

output "cluster_name" {
  value = "${var.cluster_name}"
}

output "instances" {
  value = "${var.instances}"
}

