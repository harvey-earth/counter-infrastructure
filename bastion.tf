resource "aws_subnet" "bastion" {
  vpc_id            = aws_vpc.counter.id
  cidr_block        = var.bastion_cidr
  availability_zone = var.avail_zone

  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow SSH traffic to bastion"
  vpc_id      = aws_vpc.counter.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-ssh"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.image
  instance_type          = var.bastion_size
  key_name               = var.counter-key-pair
  subnet_id              = aws_subnet.bastion.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    delete_on_termination = true
    volume_size           = var.root_disk_size
    volume_type           = var.root_disk_type
  }

  tags = {
    Name        = "bastion"
    Application = "counter"
  }

  provisioner "file" {
    source      = "ansible"
    destination = "./"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.SSH_KEY
      host        = aws_instance.bastion.ipv4_address
      timeout     = "20s"
    }
  }

  provisioner "file" {
    source      = "inventory"
    destination = "./inventory"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.SSH_KEY
      host        = aws_instance.bastion.ipv4_address
      timeout     = "20s"
    }
  }

  provisioner "file" {
    source      = "id_ed25519.pub"
    destination = ".ssh/id_ed25519.pub"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.SSH_KEY
      host        = aws_instance.bastion.ipv4_address
      timeout     = "20s"
    }
  }

  provisioner "file" {
    source      = "id_ed25519"
    destination = ".ssh/id_ed25519"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.SSH_KEY
      host        = aws_instance.bastion.ipv4_address
      timeout     = "20s"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "chmod 600 ~/.ssh/id_ed25519",
      "apt update",
      "apt install ansible -y",
      "mv ansible/ansible.cfg ./",
      "ansible-playbook -i inventory ansible/main.yaml -e '{\"app_cidr\":\"${var.web_cidr}\",\"postgres_password\":\"${var.pg_password}\"}'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.SSH_KEY
      host        = aws_instance.bastion.ipv4_address
      timeout     = "20s"
    }
  }
}

resource "local_file" "ssh_pub_key" {
  content  = var.counter-key-pair-value
  filename = "id_ed25519.pub"
}

resource "local_file" "ssh_key" {
  content  = var.SSH_KEY
  filename = "id_ed25519"
}
