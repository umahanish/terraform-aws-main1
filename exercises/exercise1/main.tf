terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.66.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
#  access_key = "AKIAVDHCAJY2Z2NDAMS2"
#  secret_key = "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"
shared_credentials_file = "c:/Users/CognexLeno/.aws/credentails"

}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Cloudtraining"
    Demo = "Terraform"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Subnet1"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "Subnet2"
    Type = "Public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"  = "Main"
    "Owner" = "Cloudtraining"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "webserver" {
  name        = "Webserver"
  description = "Webserver network traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.workstation_ip]
  }

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
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
    Name = "Allow traffic"
  }
}

  resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "demo_key" {
  key_name   = var.demo_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

 /* provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.demo_key_name}'.pem
      chmod 400 ./'${var.demo_key_name}'.pem
    EOT
  }*/

}
resource "local_file" "demo_key" {
    content  = tls_private_key.dev_key.private_key_pem
    filename = "demo_key"
}

resource "aws_instance" "web" {
  ami                    = var.amis[var.region]
  instance_type          = var.instance_type
  key_name               = var.demo_key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  associate_public_ip_address = true
  #userdata
  user_data = <<EOF
  #!/bin/bash
  sudo yum update –y
  sudo yum install -y httpd
  sudo service httpd start
  sudo chkconfig httpd on
  sudo groupadd www
  sudo usermod -a -G www ec2-user
  sudo chown ec2-user /var/www/html/ -R
  sudo echo "Auto-Scaling of webserver" > /var/www/html/index.html
  EOF
  tags = {
    Name = "Cloudtraining"
  }
}
