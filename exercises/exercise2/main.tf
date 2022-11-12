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
  shared_credentials_file = "c:/Users/CognexLeno/.aws/credentails"
}

/*data "aws_ami_ids" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
   # values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["350513810997"]
}*/

/*data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["350513810997"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd/ubuntu-focal-20.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_ami_copy" "ubuntu_encrypted_ami" {
  name              = "ubuntu-encrypted-ami"
  description       = "An encrypted root ami based off ${data.aws_ami.ubuntu.id}"
  source_ami_id     = data.aws_ami.ubuntu.id
  source_ami_region = "us-east-2"
  encrypted         = true

  tags = { Name = "ubuntu-encrypted-ami" }
}

data "aws_ami" "encrypted-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [aws_ami_copy.ubuntu_encrypted_ami.id]
  }

  owners = ["self"]
}*/

resource "aws_instance" "name" {
  instance_type = var.instance_type
  ami = var.dev_ami
  instance = var.instance_count
  
}


resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "CloudAcademy"
    Demo = "Terraform"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Public-Subnet1"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 2)
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "Public-Subnet2"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 3)
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "Private-Subnet3"
    Type = "Private"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 4)
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "Private-Subnet4"
    Type = "Private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"  = "Main"
    "Owner" = "CloudAcademy"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
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

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private"
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

resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "webserver" {
  name        = "webserver"
  description = "webserver network traffic"
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
    cidr_blocks = [
      cidrsubnet(var.cidr_block, 8, 1),
      cidrsubnet(var.cidr_block, 8, 2)
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow traffic"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "alb network traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.webserver.id]
  }

  tags = {
    Name = "allow traffic"
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
/*resource "aws_launch_template" "launchtemplate1" {
  name = "web"

  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.demo_key_name
  vpc_security_group_ids = [aws_security_group.webserver.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "WebServer"
    }
  }

  user_data = filebase64("${path.module}/ec2.userdata")
}*/

resource "aws_lb" "alb1" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  enable_deletion_protection = false

  /*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
  */

  tags = {
    Environment = "Prod"
  }
}

resource "aws_alb_target_group" "webserver" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }
}

resource "aws_alb_listener_rule" "rule1" {
  listener_arn = aws_alb_listener.front_end.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.subnet3.id, aws_subnet.subnet4.id]

  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  target_group_arns = [aws_alb_target_group.webserver.arn]

/*  launch_template {
    id      = aws_launch_template.launchtemplate1.id
    version = "$Latest"
  }*/
}
