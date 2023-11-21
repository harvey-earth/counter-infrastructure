resource "aws_subnet" "database" {
  vpc_id            = aws_vpc.counter.id
  cidr_block        = var.db_cidr
  availability_zone = var.avail_zone

  tags = {
    Name        = "database"
    Application = "counter"
  }
}

resource "aws_security_group" "db_pg" {
  name        = "db-pg"
  description = "Allow PostgreSQL traffic to database"
  vpc_id      = aws_vpc.counter.id

  ingress = [
    {
      description     = "PostgreSQL from app servers"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = aws_security_group.web.id
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
    Name        = "pg"
    Application = "counter"
  }
}

resource "aws_security_group" "db_redis" {
  name        = "db-redis"
  description = "Allow Redis traffic to database"
  vpc_id      = aws_vpc.counter.id

  ingress = [
    {
      description     = "Redis from app servers"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = aws_security_group.web.id
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
    Name        = "redis"
    Application = "counter"
  }
}

resource "aws_instance" "postgres" {
  ami                    = var.image
  instance_type          = var.db_size
  key_name               = var.counter-key-pair
  subnet_id              = aws_subnet.database.id
  vpc_security_group_ids = [aws_security_group.db_pg.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = var.db_disk_size
    volume_type           = var.root_disk_type
  }

  tags = {
    Name        = "postgres"
    Application = "counter"
  }
}

resource "aws_instance" "redis" {
  ami                    = var.image
  instance_type          = var.redis_size
  key_name               = var.counter-key-pair
  subnet_id              = aws_subnet.database.id
  vpc_security_group_ids = [aws_security_group.db_redis.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = var.root_disk_size
    volume_type           = var.root_disk_type
  }

  tags = {
    Name        = "redis"
    Application = "counter"
  }
}
