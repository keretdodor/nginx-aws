######################################################################
###                         NGINX Instance 
######################################################################
resource "aws_instance" "nginx" {
  count                    = 2
  ami                      = data.aws_ami.ubuntu_ami.id
  key_name                 = aws_key_pair.nginx_key.key_name
  instance_type            = var.instance_type
  subnet_id                = var.private_subnets[count.index % length(var.private_subnets)]
  vpc_security_group_ids   = [aws_security_group.nginx_sg.id]
  tags = {
    Name = "nginx"
  }
}

resource "aws_key_pair" "nginx_key" {
  key_name   = "nginx-key"
  public_key = file(var.nginx_key_public) # Path to your public key
  
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow HTTP traffic only from the load balancer and bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "null_resource" "docker" {
for_each = {for idx, inst in aws_instance.nginx : idx => inst.private_ip}

provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo snap install docker",
      "sleep 7",
      "sudo systemctl start snap.docker.dockerd.service",  
      "sudo systemctl enable snap.docker.dockerd.service", 
      "sleep 7",
      "sudo docker pull keretdodor/nginx-moveo",
      "sudo docker run -d -p 80:80 keretdodor/nginx-moveo"
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file(var.nginx_key_private)
      host                = each.value
      bastion_host        = var.bastion_public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file(var.bastion_key_private)
    }
  }
  depends_on = [var.nat_gateway_id]
}

######################################################################
###                         Route 53 A Record 
######################################################################

resource "aws_route53_record" "lb-alias" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id 
  name    = var.alias_record
  type    = "A"

  alias {
    name                   = aws_lb.nginx.dns_name
    zone_id                = aws_lb.nginx.zone_id
    evaluate_target_health = true
  }
}

######################################################################
###                 Load Balancer and Target Group
######################################################################
resource "aws_lb" "nginx" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnets

} 
resource "aws_lb_target_group" "nginx-tg" {
  name     = "nginx-tg"
  port     = 80
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
  for_each = {for idx in range(length(aws_instance.nginx)) : idx => aws_instance.nginx[idx].id}
  target_group_arn = aws_lb_target_group.nginx-tg.arn
  target_id        = each.value
  port             = 80
}

resource "aws_lb_listener" "nginx-listener" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.cert_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-tg.arn
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTPS traffic from clients and HTTP traffic to backends"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "lb-sg"
  }
}

