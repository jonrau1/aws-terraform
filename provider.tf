provider "aws" {
  region = "us-east-1"
}

terraform {
    backend "s3" {
      encrypt = true
      bucket = "Your_Bucket"
      dynamodb_table = "Your_DDB_Table"
      key = "path/to/terraform.tfstate"
      region = "REGION"
  }
}