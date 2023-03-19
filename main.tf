terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name ="${var.env_prefix}-vpc"

  }
}
resource "aws_subnet" "myapp-subnet-1"{
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone  = "us-west-2a"
  tags = {
    Name ="${var.env_prefix}-subnet-1"

  }
}
/*resource "aws_route_table" "myapp-route-table" {
 vpc_id = aws_vpc.myapp-vpc.id 
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.myapp-igw.id
 }
  tags = {
    Name ="${var.env_prefix}-RTB"

  }
}*/
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name ="${var.env_prefix}-IGW"

  }
}
/*resource "aws_route_table_association" "a-rtb-subent" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}*/
resource "aws_default_route_table" "main-RTB" {
default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.myapp-igw.id
 }
  tags = {
    Name ="${var.env_prefix}-MAIN-RTB"

  }
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  
}


resource "aws_instance" "we-b" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  key_name        = "DEVOPS"
  security_groups = [aws_security_group.allow_tls.id]
  associate_public_ip_address = true
  subnet_id = aws_subnet.myapp-subnet-1.id
       user_data = <<-EOF
      #!/bin/sh
      sudo apt update -y
      sudo yum install -y docker
      sudo service docker start
      sudo usermod -a -G docker ubuntu
      EOF
  tags = {
    Name =  "myec2" 
  }  
 
}

