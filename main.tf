provider "aws" {
    region = "ap-south-1"
    access_key = "AKIAXH6QHUMF6U276QV2"
    secret_key = "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"
}
variable "sn-cidr-block" {
    description = "subnet cidr block"
  
}
variable "vpc-cidr-block" {
    description = "vpc cidr block"
  
}
variable "env" {
  description = "env to deploy"
}
variable "az" {

}
variable "rtb" {
  
}
resource "aws_vpc" "ss_vpc" {
    cidr_block = var.vpc-cidr-block
    tags = {
        Name = var.env
    }
}
resource "aws_subnet" "ss-sn-1" {
   vpc_id = aws_vpc.ss_vpc.id
    cidr_block = var.sn-cidr-block
    availability_zone = var.az
    tags = {
        Name = "sssubnet01"
        subnet = "01"
    }

  
}
output "ss-vpc-id"{
    value = aws_vpc.ss_vpc.id
}
output "ss-subnet-id"{
    value = aws_subnet.ss-sn-1.id
}
resource "aws_internet_gateway" "ss-gw" {
  vpc_id = aws_vpc.ss_vpc.id

  tags = {
    Name = "${var.env}-igw"
  }
}
resource "aws_route_table" "ssmain-rtb" {
  vpc_id = aws_vpc.ss_vpc.id

  route {
    cidr_block = var.rtb
    gateway_id = aws_internet_gateway.ss-gw.id
     }
     tags = {
        Name = "${var.env}-ssmain-rtb"
     } 
     
}
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.ss-sn-1.id
  route_table_id = aws_route_table.ssmain-rtb.id

}
resource "aws_security_group" "ss-sg" {
  name        = "ss-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.ss_vpc.id


  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.rtb]
  }
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [var.rtb]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.rtb]
    prefix_list_ids  = []
  }

  tags = {
    Name = "${var.env}-sg"
  }
}
data "aws_ami" "amazon-linux-image" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}
output "ami_id"{
    value = data.aws_ami.amazon-linux-image
}
resource "aws_instance" "ss-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = "t2.micro"
  key_name                    = "java"
  associate_public_ip_address = true
  subnet_id = aws_subnet.ss-sn-1.id
  vpc_security_group_ids = [aws_security_group.ss-sg.id]
  availability_zone = var.az
  
  tags = {
 Name = "${var.env}-server"
}
user_data = <<EOF
             #!/bin/bash
             apt-get update && apt-get install -y docker-ce
             systemctl start docker
             usermod -aG docker ec2-user
             docker run -p 8080:8080 nginx
             EOF
}