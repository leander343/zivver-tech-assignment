terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.28.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure region for AWS provider
provider "aws" {
  region = "ap-south-1"
}





