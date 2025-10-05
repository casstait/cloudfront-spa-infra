terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"

}

data "aws_caller_identity" "current" {}
