##-------------------##
##  GLOBAL VARIABLES ##
##-------------------##
variable "AWS_Region" {
  default     = "us-east-1"
  description = "Region will pass to VPC Endpoints"
}
variable "Network_Resource_Count" {
  default     = 3
  description = "Amount of Network Resources Provisioned e.g. Subnets and Route Tables - Adjust for Regionally AZ Count and HA Requirements"
}
##-------------------##
##  VPC.tf VARIABLES ##
##-------------------##
variable "3Tier_VPC_CIDR" {
  default     = "172.17.0.0/16"
  description = "RFC1918 CIDR for VPC - Subnet CIDR Block Calculations will be handled by Terraform"
}
variable "3Tier_VPC_DNS_Support" {
  default     = "true"
  description = "Indicates whether the DNS resolution is supported"
}
variable "3Tier_VPC_DNS_Hostnames" {
  default     = "true"
  description = "Indicates whether instances with public IP addresses get corresponding public DNS hostnames"
}
variable "3Tier_VPC_Name_Tag" {
  default = ""
}
variable "RDS_Subnet_Group_Name" {
  default = ""
}
variable "RDS_Subnet_Group_Description" {
  default = ""
}
variable "3Tier_IGW_Name_Tag" {
  default = ""
}
variable "3Tier_Public_RTB_Name_Tag" {
  default = ""
}
variable "3Tier_FlowLogs_CWL_Group_Name" {
  default = ""
}
variable "3Tier_FlowLogs_to_CWL_Role_Name" {
  default = ""
}
variable "3Tier_FlowLogs_to_CWL_Role_Policy_Name" {
  default = ""
}
##-----------------------##
## Security.tf VARIABLES ##
##-----------------------##
variable "VPCE_Interface_SG_Name" {
  default = ""
}
variable "VPCE_Interface_SG_Description" {
  default = ""
}
variable "ALB_SG_Name" {
  default = ""
}
variable "ALB_SG_Description" {
  default = ""
}
variable "Application_SG_Name" {
  default = ""
}
variable "Application_SG_Description" {
  default = ""
}
variable "Database_SG_Name" {
  default = ""
}
variable "Database_SG_Description" {
  default = ""
}
variable "3Tier_Default_NACL_Name_Tag" {
  default = ""
}
variable "DB_Layer_NACL_Name_Tag" {
  default = ""
}
##-------------------##
## Main.tf VARIABLES ##
##-------------------##
variable "3Tier_RDS_MySQL_Allocated_Storage" {
  default     = 20
  description = "The allocated storage in gibibytes"
}
variable "3Tier_RDS_MySQL_Instance_Class" {
  default = "db.t2.micro"
}
variable "3Tier_RDS_MySQL_Name" {
  default = ""
}
variable "3Tier_RDS_MySQL_DB_Username" {
  default    = "mysqluser"
  description = "This is saved in your logs and Terraform.tfstate file - CHANGE IMMEDIATELY UPON CREATION"
}
variable "3Tier_RDS_MySQL_DB_Password" {
  default    = "changeme"
  description = "This is saved in your logs and Terraform.tfstate file - CHANGE IMMEDIATELY UPON CREATION"
}
variable "3Tier_EC2_App_Instances_Type" {
  default = "t2.micro"
}
variable "3Tier_EC2_App_Instances_Key_Pair_Name" {
  default = ""
}
variable "3Tier_EC2_App_Instances_EBS_Volume_Size" {
  default = 28
}
variable "3Tier_EC2_App_Instances_Name_Tag" {
  default = ""
}
variable "3Tier_App_Load_Balancer_AccessLogs_Bucket_Name" {
  default = ""
}
variable "3Tier_App_Load_Balancer_Name" {
  default = ""
}
variable "3Tier_App_Load_Balancer_HTTP_Target_Group_Name" {
  default     = ""
  description = "Name cannot be longer than 32 characters"
}