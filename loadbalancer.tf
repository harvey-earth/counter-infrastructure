resource "aws_security_group" "lb" {
  name        = "lb"
  description = "Allow HTTPS traffic to load balancer"
  vpc_id      = aws_vpc.counter.id

  ingress = {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "app" {
  name               = "counter"
  port               = 80
  protocol           = "HTTP"
  vpc_id             = aws_vpc.counter.id
  preserve_client_ip = true
  health_check {
    enabled  = true
    interval = 10
    matcher  = 200
    path     = "/up"
  }
}

resource "aws_lb_target_group_attachment" "attach-app" {
  for_each = {
    for k, v in aws_instance.web :
    v.id => v
  }
  target_group_arn = aws_lb_target_group.app
  target_id        = each.value.id
  port             = 80
}

resource "aws_lb" "counter" {
  name               = "counter"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.counter-public.id]

  tags = {
    Name        = "lb"
    Application = "counter"
  }
}

resource "aws_lb_listener" "counter-listener" {
  load_balancer_arn = aws_lb.counter.arn
  certificate_arn   = aws_lb_listener_certificate.counter.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# resource "aws_lb_listener_certificate" "counter" {
#   listener_arn    = aws_lb_listener.counter-listener.arn
#   certificate_arn = aws_acm_certificate.counter.arn
# }
