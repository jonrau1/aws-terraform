resource "aws_default_security_group" "Default_Security_Group" {
  vpc_id = "${aws_vpc.3Tier_VPC.id}"
  tags {
    Name = "DEFAULT_DO_NOT_USE"
  }
}
resource "aws_security_group" "VPCE_Interface_SG" {
  name        = "${var.VPCE_Interface_SG_Name}"
  description = "${var.VPCE_Interface_SG_Description} - Managed by Terraform"
  vpc_id      = "${aws_vpc.3Tier_VPC.id}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
      Name = "${var.VPCE_Interface_SG_Name}"
  }
}
resource "aws_security_group" "ALB_SG" {
  name        = "${var.ALB_SG_Name}"
  description = "${var.ALB_SG_Description} - Managed by Terraform"
  vpc_id      = "${aws_vpc.3Tier_VPC.id}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
      Name = "${var.ALB_SG_Name}"
  }
}
resource "aws_security_group" "Application_SG" {
  name        = "${var.Application_SG_Name}"
  description = "${var.Application_SG_Description} - Managed by Terraform"
  vpc_id      = "${aws_vpc.3Tier_VPC.id}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ALB_SG.id}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ALB_SG.id}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
      Name = "${var.Application_SG_Name}"
  }
}
resource "aws_security_group" "Database_SG" {
  name        = "${var.Database_SG_Name}"
  description = "${var.Database_SG_Description} - Managed by Terraform"
  vpc_id      = "${aws_vpc.3Tier_VPC.id}"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ALB_SG.id}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
      Name = "${var.Database_SG_Name}"
  }
}
resource "aws_default_network_acl" "3Tier_Default_NACL" {
  default_network_acl_id = "${aws_vpc.3Tier_VPC.default_network_acl_id}"
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "${var.3Tier_Default_NACL_Name_Tag}"
  }
}
resource "aws_network_acl" "DB_Layer_NACL" {
  vpc_id    = "${aws_vpc.3Tier_VPC.id}"
  subnet_ids = ["${aws_subnet.3Tier_DB_Subnets.*.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${aws_vpc.3Tier_VPC.cidr_block}"
    from_port  = 3306
    to_port    = 3306
  }
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${aws_vpc.3Tier_VPC.cidr_block}"
    from_port  = 3306
    to_port    = 3306
  }

  tags = {
    Name = "${var.DB_Layer_NACL_Name_Tag}"
  }
}