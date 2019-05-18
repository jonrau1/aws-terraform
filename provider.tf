provider "aws" {
  region = "us-east-1"
}

terraform {
    backend "s3" {
      encrypt = true
      bucket = "mobjaguar-tf-remotes-novamain"
      dynamodb_table = "mobjaguar-tf-remotes-ddb-novamain"
      key = "iad/treeteer/terraform.tfstate"
      region = "us-east-1"
  }
}