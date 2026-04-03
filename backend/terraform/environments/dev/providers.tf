terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "youngbaby-terraform-state-912542578074"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "youngbaby-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
