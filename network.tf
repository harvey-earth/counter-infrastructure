# Set up Private Network so only Load Balancer(s) exposed
resource "aws_vpc" "counter" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "counter"
  }
}

resource "aws_subnet" "counter-public" {
  vpc_id                  = aws_vpc.counter.id
  cidr_block              = var.public_cidr
  availability_zone       = var.avail_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "counter-public"
    Application = "counter"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = var.AWS_ZONE_ID
  name    = var.bastion_host
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.ipv4_address]
}

resource "aws_route53_record" "counter" {
  zone_id = var.AWS_ZONE_ID
  name    = var.host_name
  type    = "A"
  ttl     = "300"
  records = [aws_lb.counter.dns_name]
}

resource "aws_acm_certificate" "counter" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "counter SSL cert"
  }
  depends_on = [aws_route53_record.counter]
}
