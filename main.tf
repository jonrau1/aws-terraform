resource "aws_db_instance" "3Tier_RDS_MySQL" {
  allocated_storage           = "${var.3Tier_RDS_MySQL_Allocated_Storage}"
  engine                      = "mysql"
  storage_type                = "gp2"
  engine_version              = "5.7"
  parameter_group_name        = "${aws_db_parameter_group.3Tier_RDS_MySQL_Param_Group.name}"
  instance_class              = "${var.3Tier_RDS_MySQL_Instance_Class}"
  name                        = "${var.3Tier_RDS_MySQL_Name}"
  username                    = "${var.3Tier_RDS_MySQL_DB_Username}"
  password                    = "${var.3Tier_RDS_MySQL_DB_Password}"
  db_subnet_group_name        = "${aws_db_subnet_group.RDS_Subnet_Group.id}"
  vpc_security_group_ids      = ["${aws_security_group.Database_SG.id}"]
  skip_final_snapshot         = true
  multi_az                    = true
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
}
resource "aws_db_parameter_group" "3Tier_RDS_MySQL_Param_Group" {
  name        = "${var.3Tier_RDS_MySQL_Name}-parameter-group"
  description = "Parameter Group for ${var.3Tier_RDS_MySQL_Name} - Managed by Terraform"
  family      = "mysql5.7"
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
resource "aws_instance" "3Tier_EC2_App_Instances" {
  count                  = "${var.Compute_Resource_Count}"
  ami                    = "${data.aws_ami.Latest_Ubuntu_18_04_AMI.id}"
  instance_type          = "${var.3Tier_EC2_App_Instances_Type}"
  key_name               = "${var.3Tier_EC2_App_Instances_Key_Pair_Name}"
  vpc_security_group_ids = ["${aws_security_group.Application_SG.id}"]
  subnet_id              = "${element(aws_subnet.3Tier_Private_Subnets.*.id, count.index)}"
  ebs_block_device {
      device_name        = "/dev/sdf"
      volume_type        = "gp2"
      volume_size        = "${var.3Tier_EC2_App_Instances_EBS_Volume_Size}"
  }
  volume_tags {
      Name = "${var.3Tier_EC2_App_Instances_Name_Tag}-EBS-Volume-${count.index}"
  }

  tags  {
    Name = "${var.3Tier_EC2_App_Instances_Name_Tag}-Instance-${count.index}"
  }
}
resource "aws_s3_bucket" "3Tier_App_Load_Balancer_AccessLogs_Bucket" {
  bucket = "${var.3Tier_App_Load_Balancer_AccessLogs_Bucket_Name}"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}
resource "aws_alb" "3Tier_App_Load_Balancer" {
  name            = "${var.3Tier_App_Load_Balancer_Name}"
  subnets         = ["${aws_subnet.3Tier_Public_Subnets.*.id}"]
  security_groups = ["${aws_security_group.ALB_SG.id}"]
  access_logs {
    enabled = true
    bucket  = "${aws_s3_bucket.3Tier_App_Load_Balancer_AccessLogs_Bucket.id}"
    prefix  = "${var.3Tier_App_Load_Balancer_Name}-logs"
  }
}
resource "aws_alb_target_group" "3Tier_App_Load_Balancer_HTTP_Target_Group" {
  name        = "${var.3Tier_App_Load_Balancer_HTTP_Target_Group_Name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.3Tier_VPC.id}"
  target_type = "instance"
}
resource "aws_alb_target_group_attachment" "3Tier_App_Load_Balancer_HTTP_Target_Group_Attachment" {
  count            = "${var.Compute_Resource_Count}"
  target_group_arn = "${aws_alb_target_group.3Tier_App_Load_Balancer_HTTP_Target_Group.arn}"
  target_id        = "${element(aws_instance.3Tier_EC2_App_Instances.*.id, count.index)}"
}
resource "aws_alb_listener" "3Tier_App_Load_Balancer_HTTP_Front_End" {
  load_balancer_arn = "${aws_alb.3Tier_App_Load_Balancer.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.3Tier_App_Load_Balancer_HTTP_Target_Group.id}"
    type             = "forward"
  }
}