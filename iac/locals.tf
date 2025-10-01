data "aws_availability_zones" "available" {}

locals {
  cluster_name = "cineagile-eks-${random_integer.suffix.result}"
  cluster_name_2 = "cineagile-eks-${random_integer.suffix.result}"
}

resource "random_integer" "suffix" {
  min = 100
  max = 999
}