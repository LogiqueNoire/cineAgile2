terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }

  required_version = ">1.0"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}