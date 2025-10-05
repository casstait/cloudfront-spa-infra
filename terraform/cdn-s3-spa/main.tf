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
  region = var.region

}

data "aws_caller_identity" "current" {}
