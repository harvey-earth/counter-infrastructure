resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.counter.id
  cidr_block        = var.web_cidr
  availability_zone = var.avail_zone

  tags = {
    Name        = "web"
    Application = "counter"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow HTTP traffic to webservers"
  vpc_id      = aws_vpc.counter.id

  ingress = [
    {
      description     = "HTTP from load balancers"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = aws_security_group.lb.id
    },
    {
      description     = "SSH from bastion"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = aws_security_group.bastion.id
    }
  ]

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web"
    Application = "counter"
  }
}

resource "aws_instance" "web" {
  ami                    = var.image
  count                  = var.app_count
  instance_type          = var.app_size
  key_name               = var.counter-key-pair
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = var.root_disk_size
    volume_type           = var.root_disk_type
  }

  tags = {
    Name        = "web-${count.index + 1}"
    Application = "counter"
  }
}