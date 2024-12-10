######################################################################
###                     VPC Creation
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
###                     Internet Gateway Creation
######################################################################
resource "aws_internet_gateway" "nginx_igw" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "nginx-igw"
  }
}

######################################################################
###                    Subnets Creation
######################################################################
resource "aws_subnet" "nginx_public_subnet" {
  vpc_id                  = aws_vpc.nginx_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
availability_zone = data.aws_availability_zones.available_azs.names[0]
  tags = {
    Name = "nginx-public-subnet"
  }
}
resource "aws_subnet" "nginx_private_subnet" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  tags = {
    Name = "nginx-private-subnet"
  }
}
######################################################################
###                    Nat Gateway Creation
######################################################################
resource "aws_nat_gateway" "nginx_nat" {
  allocation_id = aws_eip.nginx_nat.id
  subnet_id     = aws_subnet.nginx_public_subnet.id
  tags = {
    Name = "nginx-nat-gateway"
  }
}

resource "aws_eip" "nginx_nat" {
  vpc = true
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

resource "aws_route_table_association" "nginx_public" {
  subnet_id      = aws_subnet.nginx_public_subnet.id
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

resource "aws_route_table_association" "nginx_private" {
  subnet_id      = aws_subnet.nginx_private_subnet.id
  route_table_id = aws_route_table.nginx_private_route_table.id
}

######################################################################
###                         Bastion Host
######################################################################

resource "aws_instance" "nginx_bastion" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.nginx_public_subnet.id
  security_groups = [
    aws_security_group.nginx_bastion_sg.name
  ]
  tags = {
    Name = "nginx-bastion-host"
  }
}

resource "aws_key_pair" "nginx_bastion_key" {
  key_name   = "nginx-bastion-key"
}
