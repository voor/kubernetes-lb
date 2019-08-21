provider "aws" {
  version = "~> 1.60"
}

terraform {
  required_version = "< 0.12.0"
}

variable "cluster_name" {}

variable "cluster_host" {
  default     = ""
}

variable "ip_address" {
  type = "list"
}

variable "vpc_id" {
  description = "PKS installation VPC id"
}

variable "tags" {
  default = ""
  description = "PKS installation VPC id"
  type = "map"
}

variable "dns_zone_id" {
  default     = ""
  description = "Zone ID for Route 53 hosted zone, no entry set if this is empty"
}

variable "public_subnet_ids" {
  description = "Public subnets where the ELB should be added."
  type = "list"
}

resource "aws_lb" "k8s_api" {
  name                             = "k8s-api-${var.cluster_name}"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  internal                         = false
  subnets                          = ["${var.public_subnet_ids}"]

  tags = "${var.tags}"
}

resource "aws_lb_listener" "k8s_api_8443" {
  load_balancer_arn = "${aws_lb.k8s_api.arn}"
  port              = 8443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.k8s_api_8443.arn}"
  }
}

resource "aws_lb_target_group" "k8s_api_8443" {
  name     = "${var.cluster_name}-k8s-tg-8443"
  port     = 8443
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"

  target_type = "ip"

  tags = "${var.tags}"
}

resource "aws_lb_target_group_attachment" "k8s_api_8443_attachment" {
  target_group_arn = "${aws_lb_target_group.k8s_api_8443.arn}"
  target_id        = "${element(var.ip_address, count.index)}"
  port             = 8443

  count = "${length(var.ip_address)}"
}

resource "aws_route53_record" "k8s_api_dns" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.cluster_host}"
  type    = "A"

  alias {
    name                   = "${aws_lb.k8s_api.dns_name}"
    zone_id                = "${aws_lb.k8s_api.zone_id}"
    evaluate_target_health = true
  }

  count = "${var.dns_zone_id != "" && var.cluster_host != "" ? 1 : 0}"
}

output "cluster_host" {
  value = "${var.cluster_host}"
}

output "cluster_name" {
  value = "${var.cluster_name}"
}

output "ip_address" {
  value = "${var.ip_address}"
}
