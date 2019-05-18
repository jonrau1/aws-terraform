resource "aws_vpc" "3Tier_VPC" {
  cidr_block           = "${var.3Tier_VPC_CIDR}"
  enable_dns_support   = "${var.3Tier_VPC_DNS_Support}"
  enable_dns_hostnames = "${var.3Tier_VPC_DNS_Hostnames}"
  tags {
      Name = "${var.3Tier_VPC_Name_Tag}"
  }
}
resource "aws_subnet" "3Tier_Public_Subnets" {
  count                   = "${var.Network_Resource_Count}"
  vpc_id                  = "${aws_vpc.3Tier_VPC.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.3Tier_VPC.cidr_block, 8, var.Network_Resource_Count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.Available_AZ.names[count.index]}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.3Tier_VPC_Name_Tag}-PUB-Subnet-${element(data.aws_availability_zones.Available_AZ.names, count.index)}"
  }
}
resource "aws_subnet" "3Tier_Private_Subnets" {
  count             = "${var.Network_Resource_Count}"
  vpc_id            = "${aws_vpc.3Tier_VPC.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.3Tier_VPC.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.Available_AZ.names[count.index]}"
  tags {
    Name = "${var.3Tier_VPC_Name_Tag}-PRIV-Subnet-${element(data.aws_availability_zones.Available_AZ.names, count.index)}"
  }
}
resource "aws_subnet" "3Tier_DB_Subnets" {
  count                   = "${var.Network_Resource_Count}"
  vpc_id                  = "${aws_vpc.3Tier_VPC.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.3Tier_VPC.cidr_block, 8, var.Network_Resource_Count + count.index + 6)}"
  availability_zone       = "${element(data.aws_availability_zones.Available_AZ.names, count.index)}"
  tags {
    Name = "${var.3Tier_VPC_Name_Tag}-RDS-Subnet-${element(data.aws_availability_zones.Available_AZ.names, count.index)}"
  }
}
resource "aws_db_subnet_group" "RDS_Subnet_Group" {
  name        = "${var.RDS_Subnet_Group_Name}"
  description = "${var.RDS_Subnet_Group_Description} - Managed By Terraform"
  subnet_ids  = [
      "${aws_subnet.3Tier_DB_Subnets.*.id}"
    ]
}
resource "aws_internet_gateway" "3Tier_IGW" {
  vpc_id = "${aws_vpc.3Tier_VPC.id}"
  tags {
      Name = "${var.3Tier_IGW_Name_Tag}"
  }
}
resource "aws_route_table" "3Tier_Public_RTB" {
  count  = "${var.Network_Resource_Count}"
  vpc_id = "${aws_vpc.3Tier_VPC.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.3Tier_IGW.id}"
  }
  tags {
    Name = "PUB-RTB-${element(aws_subnet.3Tier_Public_Subnets.*.id, count.index)}"
  }
}
resource "aws_eip" "NATGW_Elastic_IPs" {
  count      = "${var.Network_Resource_Count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.3Tier_IGW"]
  tags {
    Name = "NAT-Gateway-EIP-${element(aws_subnet.3Tier_Public_Subnets.*.id, count.index)}"
  }
}
resource "aws_nat_gateway" "3Tier_NAT_Gateway" {
  count         = "${var.Network_Resource_Count}"
  subnet_id     = "${element(aws_subnet.3Tier_Public_Subnets.*.id, count.index)}"
  allocation_id = "${element(aws_eip.NATGW_Elastic_IPs.*.id, count.index)}"
  tags {
    Name = "NAT-Gateway-${element(aws_subnet.3Tier_Public_Subnets.*.id, count.index)}"
  }
}
resource "aws_route_table" "3Tier_Private_RTB" {
  count  = "${var.Network_Resource_Count}"
  vpc_id = "${aws_vpc.3Tier_VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.3Tier_NAT_Gateway.*.id, count.index)}"
  }
  tags {
    Name = "PRIV-RTB-${element(aws_subnet.3Tier_Private_Subnets.*.id, count.index)}"
  }
}
resource "aws_route_table_association" "Public_Subnet_Association" {
  count          = "${var.Network_Resource_Count}"
  subnet_id      = "${element(aws_subnet.3Tier_Public_Subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.3Tier_Private_RTB.*.id, count.index)}"
}
resource "aws_route_table_association" "Private_Subnet_Association" {
  count          = "${var.Network_Resource_Count}"
  subnet_id      = "${element(aws_subnet.3Tier_Private_Subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.3Tier_Private_RTB.*.id, count.index)}"
}
resource "aws_route_table_association" "DB_Subnet_Association" {
  count          = "${var.Network_Resource_Count}"
  subnet_id      = "${element(aws_subnet.3Tier_DB_Subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.3Tier_Private_RTB.*.id, count.index)}"
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Gateway_S3" {
  vpc_id            = "${aws_vpc.3Tier_VPC.id}"
  service_name      = "com.amazonaws.${var.AWS_Region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [
    "${aws_route_table.3Tier_Public_RTB.id}",
    "${aws_route_table.3Tier_Private_RTB.*.id}"
  ]
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Interface_Cloudwatch_Logs" {
  vpc_id             = "${aws_vpc.3Tier_VPC.id}"
  service_name       = "com.amazonaws.${var.AWS_Region}.logs"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["${aws_security_group.VPCE_Interface_SG.id}"]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Interface_SSM" {
  vpc_id             = "${aws_vpc.3Tier_VPC.id}"
  service_name       = "com.amazonaws.${var.AWS_Region}.ssm"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["${aws_security_group.VPCE_Interface_SG.id}"]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Interface_SSMMessages" {
  vpc_id             = "${aws_vpc.3Tier_VPC.id}"
  service_name       = "com.amazonaws.${var.AWS_Region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["${aws_security_group.VPCE_Interface_SG.id}"]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Interface_EC2" {
  vpc_id             = "${aws_vpc.3Tier_VPC.id}"
  service_name       = "com.amazonaws.${var.AWS_Region}.ec2"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["${aws_security_group.VPCE_Interface_SG.id}"]
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "3Tier_VPCE_Interface_EC2Messages" {
  vpc_id             = "${aws_vpc.3Tier_VPC.id}"
  service_name       = "com.amazonaws.${var.AWS_Region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["${aws_security_group.VPCE_Interface_SG.id}"]
  private_dns_enabled = true
}
resource "aws_flow_log" "3Tier_VPC_Flow_Log" {
  iam_role_arn    = "${aws_iam_role.3Tier_FlowLogs_to_CWL_Role.arn}"
  log_destination = "${aws_cloudwatch_log_group.3Tier_FlowLogs_CWL_Group.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.3Tier_VPC.id}"
}
resource "aws_cloudwatch_log_group" "3Tier_FlowLogs_CWL_Group" {
  name = "${var.3Tier_FlowLogs_CWL_Group_Name}"
}
resource "aws_iam_role" "3Tier_FlowLogs_to_CWL_Role" {
  name = "${var.3Tier_FlowLogs_to_CWL_Role_Name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "3Tier_FlowLogs_to_CWL_Role_Policy" {
  name = "${var.3Tier_FlowLogs_to_CWL_Role_Policy_Name}"
  role = "${aws_iam_role.3Tier_FlowLogs_to_CWL_Role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cloudwatch_log_group.3Tier_FlowLogs_CWL_Group.arn}*"
    }
  ]
}
EOF
}