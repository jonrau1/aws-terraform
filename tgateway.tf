data "aws_availability_zones" "available" {
  state = "available"
} 

resource "aws_vpc" "vpc_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "snet1" {
  vpc_id     = "${aws_vpc.vpc_main.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "Subnet1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc_main.id}"

  tags = {
    Name = "VPCMainIGW"
  }
}

resource "aws_route_table" "mainrtb" {
  vpc_id = "${aws_vpc.vpc_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "VPCMainRTB"
  }
}

resource "aws_route_table_association" "rtb-a1" {
  subnet_id      = "${aws_subnet.snet1.id}"
  route_table_id = "${aws_route_table.mainrtb.id}"
}

resource "aws_ec2_transit_gateway" "tgw" {
  description = "Hey Mom, Testing Out T-Gateway"
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support = "enable"
  tags {
    Name = "MainTGateway"
	ENV = "Non-Prod"
	CostCenter = "1111AAAA"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachsnet1" {
  subnet_ids         = ["${aws_subnet.snet1.id}"]
  transit_gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  vpc_id             = "${aws_vpc.vpc_main.id}"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  dns_support = "enable"
  tags {
    Name = "Snet1-to-SSVC"
	ENV = "Non-Prod"
	Route = "SharedServices"
  }
}