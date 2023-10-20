terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "hernanitotal"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minha-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "minha-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "minha-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.route_table.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deployer" {
  key_name   = "video-imersao"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCcRR6JO5pWMWkZNMlQpUxqFn0anbAh/XmW65ljcNp2fL2GbkJF1NuDiAQdsPHJldNSim4D1O9n5KA/Y3NYpgCUr8gW5AoeP0GHfMIK10BH4oyJRHqiODUACfCWBePOMiyDU2MI6I6FmLcsCjAs/BY9OQunPx7ZZCblkSJgvarxC7lOHZGu2tPcexDUZMf72/3SsKzVFozbSI7nrsBCuBqcnVMiH72ClHHA7V971MXwvvOnlU1hjrt20ZTN1IuTqal7REfhYp53NVRaWBrdjiikTTqYbryMHXGdXdbREtbWAuXqndBSRWv+IfgjKIthLcQnmyLEJnBKK3Y0hJlhz9GF/+bAlC10fwK0LWD/rBPfxCCRCBPzX7dleN9EpBPAmZoDiXWKtpJzDOIoLOw/v3+f4q1u8WSyzvS0YzGhSMSOs3+EZFxkUozyqV/UKEXHUIQyovsPmGB5eDf0kQpUjkg4QYWPxOmPwS2CqY8v9JaPLl+nU4v6qoAeBODoJScDUf8= usuario@ramper03"
}


resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id      = aws_subnet.main.id
  associate_public_ip_address = true
  key_name = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    Name = "minha-ec2"
  }
}

resource "aws_security_group" "security_group" {
  name        = "imersao_security_group"
  description = "SG Liberado"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tudo_liberado"
  }
}

output "ip" {
    value = aws_instance.web.public_ip
  
}