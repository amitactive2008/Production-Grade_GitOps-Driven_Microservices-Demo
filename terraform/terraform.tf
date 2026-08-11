terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.58.0"
    }
  }
    backend "s3" {
    bucket = "devopsdock-terraform-backend-bucket-088317451471-ap-south-1-an"
    key    = "s3-backend"
    region = "ap-south-1"
    use_lockfile = true # Enables native S3 state locking
  }
}

provider "aws" {
  region = "ap-south-1"
}

