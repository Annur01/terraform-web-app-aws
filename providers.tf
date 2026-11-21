# Require a minimum Terraform version and declare the AWS provider plugin
terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS provider with your target region
provider "aws" {
  region = "ap-southeast-5"
}