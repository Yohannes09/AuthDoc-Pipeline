resource "aws_lb" "load_balancer"{
  name = "${var.env}-nlb"
  load_balancer_type = "network"
  internal = false
  enable_cross_zone_load_balancing = var.env == "prod" ? true : false
  subnets = var.public_subnet_ids
}

resource "aws_lb_target_group" "nginx-ingress" {
  name     = "${var.env}-nginx-ingress-group"
  port     = var.nginx_nodeport
  protocol = "TCP"
  target_type = var.target_type
  vpc_id   = var.vpc_id

  health_check {
    protocol = "HTTP"
    port = "10254"
    path = "/healthz"
    healthy_threshold = 2 # Number of consecutive health check successes required before considering a target healthy. The range is 2-10. Defaults to 3.
    unhealthy_threshold = 2
    interval = 10 # Approximate amount of time, in seconds, between health checks of an individual target.
  }
}

# Registers EC2 instances into the NLB's target group
# NLB needs to know which machines to forward traffic to
resource "aws_lb_target_group_attachment" "lb_to_nginx" {
  count = length(var.worker_node_ids)
  target_group_arn = aws_lb_target_group.nginx-ingress.arn
  target_id        = var.worker_node_ids[count.index]
  port = var.nginx_nodeport
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = "443"
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nginx-ingress.arn
  }
}