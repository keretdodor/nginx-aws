######################################################################
###                            VPC Creation
######################################################################
resource "aws_vpc" "nginx_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "nginx-vpc"
  }
}
######################################################################
###                          Internet Gateway
######################################################################
resource "aws_internet_gateway" "nginx_igw" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "nginx-igw"
  }
}

######################################################################
###                     Private and Public Subnets
######################################################################

resource "aws_subnet" "nginx_public_subnet-1" {
  vpc_id                  = aws_vpc.nginx_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  tags = {
    Name = "nginx-public-subnet"
  }
}

resource "aws_subnet" "nginx_public_subnet-2" {
  vpc_id                  = aws_vpc.nginx_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  tags = {
    Name = "nginx-public-subnet"
  }
}

resource "aws_subnet" "nginx_private_subnet-1" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  tags = {
    Name = "nginx-private-subnet-1"
  }
}
resource "aws_subnet" "nginx_private_subnet-2" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  tags = {
    Name = "nginx-private-subnet-2"
  }
}
######################################################################
###                             NACLs
######################################################################


resource "aws_network_acl" "nginx_public_nacl" {
  vpc_id = aws_vpc.nginx_vpc.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [
    aws_subnet.nginx_public_subnet-1.id,
    aws_subnet.nginx_public_subnet-2.id
  ]

  tags = {
    Name = "nginx-public-nacl"
  }
}

resource "aws_network_acl" "nginx_private_nacl" {
  vpc_id = aws_vpc.nginx_vpc.id
  
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.bastion_private_ip}/32"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.0.0/16"  # VPC CIDR
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  subnet_ids = [
    aws_subnet.nginx_private_subnet-1.id,
    aws_subnet.nginx_private_subnet-2.id
  ]

  tags = {
    Name = "nginx-private-nacl"
  }
}
######################################################################
###                    Nat Gateway and Elastic IP
######################################################################
resource "aws_nat_gateway" "nginx_nat" {
  allocation_id = aws_eip.nginx_nat.id
  subnet_id     = aws_subnet.nginx_public_subnet-1.id
  tags = {
    Name = "nginx-nat-gateway"
  }
}

resource "aws_eip" "nginx_nat" {
  tags = {
    Name = "nginx-nat-eip"
  }
}

######################################################################
###                  Private and Public Route Tables
######################################################################

resource "aws_route_table" "nginx_public_route_table" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "nginx-public-route-table"
  }
}

resource "aws_route" "nginx_public_route" {
  route_table_id         = aws_route_table.nginx_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nginx_igw.id
}

resource "aws_route_table_association" "nginx_public-1" {
  subnet_id      = aws_subnet.nginx_public_subnet-1.id
  route_table_id = aws_route_table.nginx_public_route_table.id
}

resource "aws_route_table_association" "nginx_public-2" {
  subnet_id      = aws_subnet.nginx_public_subnet-2.id
  route_table_id = aws_route_table.nginx_public_route_table.id
}

resource "aws_route_table" "nginx_private_route_table" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "nginx-private-route-table"
  }
}

resource "aws_route" "nginx_private_route" {
  route_table_id         = aws_route_table.nginx_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nginx_nat.id
}

resource "aws_route_table_association" "nginx_private-1" {
  subnet_id      = aws_subnet.nginx_private_subnet-1.id
  route_table_id = aws_route_table.nginx_private_route_table.id
}

resource "aws_route_table_association" "nginx_private-2" {
  subnet_id      = aws_subnet.nginx_private_subnet-2.id
  route_table_id = aws_route_table.nginx_private_route_table.id
}

######################################################################
###                         Bastion Host
######################################################################

resource "aws_instance" "nginx_bastion" {
  ami                      = data.aws_ami.ubuntu_ami.id
  instance_type            = var.instance_type
  key_name                 = aws_key_pair.bastion_key.key_name
  subnet_id                = aws_subnet.nginx_public_subnet-1.id
  vpc_security_group_ids   = [aws_security_group.nginx_bastion_sg.id]
  tags = {
    Name = "nginx-bastion-host"
  }
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file(var.bastion_key_public) # Path to your public key
}

resource "aws_security_group" "nginx_bastion_sg" {
  name        = "bastion-sg"  
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.nginx_vpc.id

  ingress {
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
  

}