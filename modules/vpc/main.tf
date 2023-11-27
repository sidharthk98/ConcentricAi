# ----------------------------------------------------------
# VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# ----------------------------------------------------------
# Public default subnets

resource "aws_route_table" "public-rt" {
  vpc_id = aws_default_vpc.default.id
}

# Create IGW for the public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_default_vpc.default.id

  tags = {
    Name = "default-igw"
  }
}

# Route the public subnet traffic through the IGW

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_default_subnet" "default-public" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default public subnet for bastion hosts"
  }
}

resource "aws_route_table_association" "public-rta" {
  subnet_id      = aws_default_subnet.default-public.id
  route_table_id = aws_route_table.public-rt.id
}

output "public-subnet" {
  value = aws_default_subnet.default-public.id
}

# --------------------------------------------------------
# Private default subnet

resource "aws_route_table" "private-rt" {
  vpc_id = aws_default_vpc.default.id
}



resource "aws_default_subnet" "default-private-1" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "Default private subnet for eks cluster"
  }
}

resource "aws_default_subnet" "default-private-2" {
  availability_zone = "us-east-1c"

  tags = {
    Name = "Default private subnet for eks cluster"
  }
}
# ------------------------------------------------------

# Create Elastic IP
resource "aws_eip" "eip-1" {
  domain = "vpc"
}

# Create NAT Gateway
resource "aws_nat_gateway" "private-main-1" {
  allocation_id = aws_eip.eip-1.id
  subnet_id     = aws_default_subnet.default-public.id

  tags = {
    Name = "NAT Gateway for Custom Kubernetes Cluster"
  }
}

# -------------------------------------------------------
# Add route to route table
resource "aws_route" "private-route-a" {
  route_table_id         = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.private-main-1.id
}

# --------------------------------------------------------
# Route table association

resource "aws_route_table_association" "private-rta-1" {
  subnet_id      = aws_default_subnet.default-private-1.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private-rta-2" {
  subnet_id      = aws_default_subnet.default-private-2.id
  route_table_id = aws_route_table.private-rt.id
}