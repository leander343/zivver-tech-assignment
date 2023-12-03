
# Retrieve all availability zones for particualr region
data "aws_availability_zones" "zones" {
  state = "available"
}

# Create VPC with /16 CIDR block
resource "aws_vpc" "ecs" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "zivvy"
  }
}

#Internet gateway to allow internet access 

resource "aws_internet_gateway" "ecs" {
  vpc_id = aws_vpc.ecs.id
  tags = {
    Name = "zivvy"
  }
}


#Public Subnets and route table associations 

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.ecs.id
  cidr_block              = cidrsubnet(aws_vpc.ecs.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  map_public_ip_on_launch = true
}

# Route traffic from subnets to internet gateway 
resource "aws_route_table" "ecs_public" {
  vpc_id = aws_vpc.ecs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs.id

  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.ecs_public.id
}


# Private Subnets, NAT gateway and route table association 

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.ecs.cidr_block, 8, 2 + count.index)
  availability_zone = data.aws_availability_zones.zones.names[count.index]
  vpc_id            = aws_vpc.ecs.id
}

# Create Elastic IP required for NAT gateway 
resource "aws_eip" "gateway" {
  count      = length(aws_subnet.private)
  depends_on = [aws_internet_gateway.ecs]
}

# Nat gateway to allow routing traffic to internet from private subnets
resource "aws_nat_gateway" "gateway" {
  count         = length(aws_subnet.private)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

# Route traffic from subnets to NAT gateways
resource "aws_route_table" "ecs_private" {
  count  = length(aws_eip.gateway)
  vpc_id = aws_vpc.ecs.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.ecs_private.*.id, count.index)
}

