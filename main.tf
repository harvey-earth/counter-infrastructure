terraform {
  # Use Terraform Cloud backend. It is synced to repo
  backend "remote" {
    hostname     = var.tfc_host
    organization = var.tfc_org
    workspaces {
      name = var.tfc_workspace
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26"
    }
  }
}

provider "aws" {
  access_key                  = var.AWS_ACCESS_KEY_ID
  region                      = var.AWS_REGION
  secret_key                  = var.AWS_SECRET_ACCESS_KEY
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Setup Key for SSH
resource "aws_key_pair" "counter" {
  key_name   = var.counter-key-pair
  public_key = var.counter-key-pair-value
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      ansible_db         = aws_instance.db.*.tags
      ansible_db_name    = aws_instance.db.*.name
      ansible_db_ip      = aws_instance.db.*.ipv4_address_private
      ansible_redis      = aws_instance.redis.*.tags
      ansible_redis_name = aws_instance.redis.*.name
      ansible_redis_ip   = aws_instance.redis.*.ipv4_address_private
      ansible_app        = aws_instance.app.*.tags
      ansible_app_name   = aws_instance.app.*.name
      ansible_app_ip     = aws_instance.app.*.ipv4_address_private
    }
  )
  filename = "inventory"
}