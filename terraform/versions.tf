terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
  }

  required_version = ">= 0.14.9"
}

data "aws_caller_identity" "current" {}
