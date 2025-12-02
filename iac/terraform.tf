terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cineagile"

    workspaces {
      prefix = "aws-infra-"
    }
  }
}