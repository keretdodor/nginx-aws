




resource "aws_route53_record" "lb-alias" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id 
  name    = var.alias_record
  type    = "A"

  alias {
    name                   = aws_lb.polybot.dns_name
    zone_id                = aws_lb.polybot.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "nginx" {
  name               = "nginx-wow"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx-sg.id]
  subnets            = var.subnet_id

} 
resource "aws_lb_target_group" "nginx-tg" {
  name     = "nginx-tg"
  port     = 433
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "nginx-attachment" {
  target_group_arn = aws_lb_target_group.nginx-tg.arn
  target_id        = each.value
  port             = 433
}

resource "aws_lb_listener" "nginx-listener" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = 433
  protocol          = "HTTPS"
  certificate_arn   = var.cert_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-tg.arn
  }
}